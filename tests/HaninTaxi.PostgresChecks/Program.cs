using System.Diagnostics;
using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Net.Sockets;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

var root = Path.GetFullPath(args.SingleOrDefault() ?? ".");
var dll = Path.Combine(root, "backend/bin/Release/net10.0/KoreanTaxi.dll");
if (!File.Exists(dll)) throw new Exception("Build backend in Release first; pass repository root as the argument.");
var admin = new NpgsqlConnectionStringBuilder(Environment.GetEnvironmentVariable("HANIN_TEST_POSTGRES")
    ?? throw new Exception("Set HANIN_TEST_POSTGRES to a disposable local PostgreSQL admin connection."));
if (admin.Host is not ("127.0.0.1" or "localhost" or "::1")) throw new Exception("Only loopback PostgreSQL is allowed.");
var name = "hanin_demo_checks_" + Guid.NewGuid().ToString("N");
var connectionString = new NpgsqlConnectionStringBuilder(admin.ConnectionString) { Database = name }.ConnectionString;
DemoDatabase.Validate(connectionString);
var signingKey = Convert.ToHexString(RandomNumberGenerator.GetBytes(48));
var options = new DbContextOptionsBuilder<TaxiDbContext>().UseNpgsql(connectionString).UseLowerCaseNamingConvention().Options;
var processes = new List<Process>();
var passed = 0;
await Sql(admin.ConnectionString, $"CREATE DATABASE {name}");
try
{
    var instances = await Task.WhenAll(Start("a"), Start("b"));
    var a = instances[0];
    var b = instances[1];
    Check(a.Process.Id != b.Process.Id, "Two independent API processes use one PostgreSQL database");

    var fixture = await Reset();
    var ordered = new List<long>();
    for (var i = 0; i < 4; i++) ordered.Add((await Match(i % 2 == 0 ? a : b))["driverQueueID"]!.GetValue<long>());
    Check(ordered.SequenceEqual(fixture.QueueOrder), "Alternating servers preserve A1, B1, A2, B2 and company FIFO");

    fixture = await Reset();
    var calls = Enumerable.Range(0, 16).Select(i => Match(i % 2 == 0 ? a : b)).ToArray();
    var offers = (await Task.WhenAll(calls)).Where(x => x["matched"]!.GetValue<bool>()).ToArray();
    Check(offers.Length == 4 && offers.Select(x => x["tripID"]!.GetValue<long>()).Distinct().Count() == 4 &&
        offers.Select(x => x["driverQueueID"]!.GetValue<long>()).Distinct().Count() == 4,
        "16 simultaneous requests create exactly four unique driver/trip offers");
    await using (var db = Context())
    {
        var persisted = await db.DriverQueues.OrderBy(x => x.CustomerQueueID).Select(x => x.DriverQueueID).ToArrayAsync();
        Check(persisted.SequenceEqual(fixture.QueueOrder), "Concurrent offers preserve company rotation in persisted customer order");
    }

    fixture = await Reset();
    await Sql(connectionString, """
        CREATE FUNCTION fail_cursor() RETURNS trigger LANGUAGE plpgsql AS $$
        BEGIN RAISE EXCEPTION 'injected commit failure'; END $$;
        CREATE TRIGGER fail_cursor BEFORE INSERT OR UPDATE ON dispatchcursors FOR EACH ROW EXECUTE FUNCTION fail_cursor();
        """);
    var failed = await a.Client.PostAsync("api/Demo/RunDispatch", null);
    Check(failed.StatusCode == HttpStatusCode.InternalServerError, "Database failure reaches the caller as a failed dispatch");
    await AssertUnchanged("Failed dispatch rolls back both queues and the rotation cursor");
    await Sql(connectionString, "DROP TRIGGER fail_cursor ON dispatchcursors; DROP FUNCTION fail_cursor()");
    Check((await Match(b))["driverQueueID"]!.GetValue<long>() == fixture.QueueOrder[0], "Another server can dispatch after rollback and lock release");

    await Stop(a.Process);
    a = await Start("a-restart");
    Check((await Match(a))["driverQueueID"]!.GetValue<long>() == fixture.QueueOrder[1], "API restart retains pending offers and continues at company B");

    fixture = await Reset();
    await Sql(connectionString, """
        CREATE FUNCTION slow_cursor() RETURNS trigger LANGUAGE plpgsql AS $$
        BEGIN PERFORM pg_sleep(30); RETURN NEW; END $$;
        CREATE TRIGGER slow_cursor BEFORE INSERT OR UPDATE ON dispatchcursors FOR EACH ROW EXECUTE FUNCTION slow_cursor();
        """);
    var interrupted = a.Client.PostAsync("api/Demo/RunDispatch", null);
    await WaitSql("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND wait_event = 'PgSleep'", 1);
    await Stop(a.Process);
    try { await interrupted; } catch (HttpRequestException) { }
    await WaitSql("SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND objid = 726104031 AND granted", 0);
    await AssertUnchanged("Killing an API during a transaction rolls back state and releases its lock");
    await Sql(connectionString, "DROP TRIGGER slow_cursor ON dispatchcursors; DROP FUNCTION slow_cursor()");
    Check((await Match(b))["driverQueueID"]!.GetValue<long>() == fixture.QueueOrder[0], "Surviving API can match the rolled-back request");
    a = await Start("a-recovery");

    foreach (var cancelFirst in new[] { true, false })
    {
        fixture = await Reset();
        var offer = await Match(a);
        var tripID = offer["tripID"]!.GetValue<long>();
        using var accept = Request("api/DriverQueue/MatchTrip", fixture.DriverLogin, "DRIVER");
        using var cancel = Request($"api/Company/CancelTrip?tripID={tripID}", fixture.CompanyLogin, "COMPANY");
        // Make both real HTTP requests wait behind a held DB lock, in a known order.
        await using var blocker = new NpgsqlConnection(connectionString);
        await blocker.OpenAsync();
        await using var transaction = await blocker.BeginTransactionAsync();
        await new NpgsqlCommand("SELECT pg_advisory_xact_lock(726104031)", blocker, transaction).ExecuteNonQueryAsync();
        var first = cancelFirst ? a.Client.SendAsync(cancel) : a.Client.SendAsync(accept);
        await WaitSql("SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND objid = 726104031 AND NOT granted", 1);
        var second = cancelFirst ? b.Client.SendAsync(accept) : b.Client.SendAsync(cancel);
        await WaitSql("SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND objid = 726104031 AND NOT granted", 2);
        await transaction.CommitAsync();
        var results = await Task.WhenAll(first, second);
        Check(results[0].IsSuccessStatusCode && (cancelFirst ? results[1].StatusCode == HttpStatusCode.BadRequest : results[1].IsSuccessStatusCode),
            cancelFirst ? "Cancel wins: stale acceptance is rejected" : "Accept wins: subsequent cancellation completes consistently");
        await using var db = Context();
        Check((await db.Trips.FindAsync(tripID))!.TripStatus == EnumTripStatus.COMPANYCANCELED &&
            !await db.CustomerQueues.AnyAsync(x => x.TripID == tripID) && !await db.DriverQueues.AnyAsync(x => x.TripID == tripID),
            "Cancellation leaves no dangling offer or accepted driver queue");
    }

    fixture = await Reset();
    await Match(a);
    using (var decline = Request("api/DriverQueue/DeclinedQueue", fixture.DriverLogin, "DRIVER"))
        Check((await b.Client.SendAsync(decline)).IsSuccessStatusCode, "Offer made on one server can be declined on the other");
    await using (var db = Context())
    {
        Check(await db.DriverQueueRejectedCustomerQueues.CountAsync() == 1 &&
            !await db.DriverQueues.AnyAsync(x => x.QueueStatus == EnumQueueStatus.PENDING) &&
            await db.CustomerQueues.AllAsync(x => x.QueueStatus == EnumQueueStatus.WAITING),
            "Decline commits rejection history and both queue states together");
    }

    fixture = await Reset();
    await Match(a);
    using (var acceptA = Request("api/DriverQueue/MatchTrip", fixture.DriverLogin, "DRIVER"))
    using (var acceptB = Request("api/DriverQueue/MatchTrip", fixture.DriverLogin, "DRIVER"))
    {
        var accepted = await Task.WhenAll(a.Client.SendAsync(acceptA), b.Client.SendAsync(acceptB));
        Check(accepted.Count(x => x.IsSuccessStatusCode) == 1 && accepted.Count(x => x.StatusCode == HttpStatusCode.BadRequest) == 1,
            "Duplicate driver acceptance across two APIs succeeds only once");
        await using var db = Context();
        Check(await db.Trips.CountAsync(x => x.TripStatus == EnumTripStatus.PICKINGUPCUSTOMER) == 1 &&
            await db.DriverQueues.CountAsync(x => x.QueueStatus == EnumQueueStatus.ACCEPTED) == 1,
            "Duplicate acceptance leaves a single assigned trip and accepted queue");
    }
    fixture = await Reset();
    var firstOffer = await Match(a);
    foreach (var column in new[] { "trip", "customer" })
    {
        await using var db = Context();
        var duplicate = await db.DriverQueues.SingleAsync(x => x.DriverQueueID == fixture.QueueOrder[1]);
        if (column == "trip") duplicate.TripID = firstOffer["tripID"]!.GetValue<long>();
        else duplicate.CustomerQueueID = firstOffer["customerQueueID"]!.GetValue<long>();
        try { await db.SaveChangesAsync(); throw new Exception("Database allowed a duplicate offer"); }
        catch (DbUpdateException error) when (error.InnerException is PostgresException { SqlState: "23505" })
        { Check(true, $"Database rejects a duplicate {column} offer even outside the API lock"); }
    }
    Console.WriteLine($"PostgreSQL integration: {passed} checks passed; two API processes, synthetic data only.");
}
finally
{
    foreach (var process in processes) await Stop(process);
    NpgsqlConnection.ClearAllPools();
    await Sql(admin.ConnectionString, $"DROP DATABASE {name} WITH (FORCE)");
}

TaxiDbContext Context() => new(options);
void Check(bool valid, string description)
{
    if (!valid) throw new Exception("FAIL: " + description);
    Console.WriteLine("PASS: " + description);
    passed++;
}
async Task AssertUnchanged(string description)
{
    await using var db = Context();
    Check(!await db.DispatchCursors.AnyAsync() && await db.DriverQueues.AllAsync(x => x.QueueStatus == EnumQueueStatus.WAITING && x.TripID == null) &&
        await db.CustomerQueues.AllAsync(x => x.QueueStatus == EnumQueueStatus.WAITING), description);
}
async Task WaitSql(string query, long expected)
{
    for (var i = 0; i < 200; i++)
    {
        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();
        if (Convert.ToInt64(await new NpgsqlCommand(query, connection).ExecuteScalarAsync()) == expected) return;
        await Task.Delay(50);
    }
    throw new Exception("Timed out waiting for database barrier: " + query);
}
static async Task Sql(string connectionString, string sql)
{
    await using var connection = new NpgsqlConnection(connectionString);
    await connection.OpenAsync();
    await new NpgsqlCommand(sql, connection).ExecuteNonQueryAsync();
}
HttpRequestMessage Request(string path, long loginID, string role)
{
    var jwt = new JwtSecurityToken(claims: [new Claim(ClaimTypes.UserData, loginID.ToString()), new Claim(ClaimTypes.Role, role)],
        expires: DateTime.UtcNow.AddMinutes(10), signingCredentials: new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)), SecurityAlgorithms.HmacSha512));
    var request = new HttpRequestMessage(HttpMethod.Post, path);
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", new JwtSecurityTokenHandler().WriteToken(jwt));
    return request;
}
static async Task<JsonObject> Match(Api api)
{
    using var result = await api.Client.PostAsync("api/Demo/RunDispatch", null);
    if (!result.IsSuccessStatusCode) throw new Exception(await result.Content.ReadAsStringAsync());
    return (await result.Content.ReadFromJsonAsync<JsonObject>())!;
}
async Task<Api> Start(string label)
{
    using var listener = new TcpListener(IPAddress.Loopback, 0);
    listener.Start();
    var port = ((IPEndPoint)listener.LocalEndpoint).Port;
    listener.Stop();
    var start = new ProcessStartInfo(Environment.GetEnvironmentVariable("DOTNET_BIN") ?? "dotnet", dll)
    { WorkingDirectory = Path.Combine(root, "backend"), RedirectStandardOutput = true, RedirectStandardError = true };
    start.Environment["DemoMode"] = "true";
    start.Environment["Demo__Postgres"] = "true";
    start.Environment["Dispatch__AutoMatch"] = "false";
    start.Environment["ConnectionStrings__DemoPostgres"] = connectionString;
    start.Environment["AppSettings__Token"] = signingKey;
    start.Environment["ASPNETCORE_URLS"] = $"http://127.0.0.1:{port}";
    start.Environment["ASPNETCORE_ENVIRONMENT"] = "Development";
    start.Environment["Logging__LogLevel__Default"] = "Error";
    start.Environment["DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE"] = "false";
    var process = Process.Start(start)!;
    lock (processes) processes.Add(process);
    var stdout = process.StandardOutput.ReadToEndAsync();
    var stderr = process.StandardError.ReadToEndAsync();
    var client = new HttpClient { BaseAddress = new Uri($"http://127.0.0.1:{port}"), Timeout = TimeSpan.FromSeconds(40) };
    for (var i = 0; i < 200; i++)
    {
        if (process.HasExited) throw new Exception($"API {label} failed: {await stdout}\n{await stderr}");
        try
        {
            var status = await client.GetFromJsonAsync<JsonObject>("api/Demo/Status");
            if (status?["persistence"]?.GetValue<string>() == "postgresql-demo") return new(process, client);
        }
        catch (HttpRequestException) { }
        await Task.Delay(100);
    }
    throw new Exception("API did not become ready: " + label);
}
static async Task Stop(Process process)
{
    if (!process.HasExited) process.Kill(entireProcessTree: true);
    await process.WaitForExitAsync();
}
async Task<Fixture> Reset()
{
    await using var db = Context();
    await db.Database.ExecuteSqlRawAsync("TRUNCATE loginusers, companies, googlelocations, dispatchcursors RESTART IDENTITY CASCADE");
    var now = DateTime.UtcNow;
    var pickup = new GoogleLocation { Name = "Synthetic pickup", Address = "Test NJ", State = EnumState.NJ, Latitude = 40.85, Longitude = -73.97 };
    var dropoff = new GoogleLocation { Name = "Synthetic dropoff", Address = "Test NY", State = EnumState.NY, Latitude = 40.75, Longitude = -73.98 };
    db.GoogleLocations.AddRange(pickup, dropoff);
    var companies = new[] { "A", "B" }.Select(name => new Company { Name = name, PhoneNumber = "2015550100", ContactName = "Test" }).ToArray();
    db.Companies.AddRange(companies);
    await db.SaveChangesAsync();
    var companyLogin = new LoginUser { Username = "operator", Password = "synthetic", Role = EnumUserRole.COMPANY };
    db.LoginUsers.Add(companyLogin);
    await db.SaveChangesAsync();
    db.CompanyUsers.Add(new CompanyUser { CompanyID = companies[0].CompanyID, LoginUserID = companyLogin.LoginUserID, Name = "Test operator" });
    var queues = new List<DriverQueue>();
    long driverLogin = 0;
    foreach (var company in companies)
    {
        db.CompanyOperatingStates.Add(new CompanyOperatingState { CompanyID = company.CompanyID, FromState = EnumState.NJ });
        for (var i = 0; i < 2; i++)
        {
            var user = new LoginUser { Username = company.Name + i, Password = "synthetic", Role = EnumUserRole.DRIVER };
            db.LoginUsers.Add(user);
            await db.SaveChangesAsync();
            if (queues.Count == 0) driverLogin = user.LoginUserID;
            var driver = new Driver { CompanyID = company.CompanyID, LoginUserID = user.LoginUserID, FirstName = company.Name, LastName = i.ToString(), PhoneNumber = "2015550102", IsAppTaxi = true, TLCApproved = true };
            db.Drivers.Add(driver);
            await db.SaveChangesAsync();
            db.Taxis.Add(new Taxi { DriverID = driver.DriverID, Model = "Synthetic", LicensePlate = $"TEST{driver.DriverID}", Size = EnumTaxiSize.SMALL });
            var queue = new DriverQueue { DriverID = driver.DriverID, Latitude = pickup.Latitude, Longitude = pickup.Longitude, CreatedDateTime = now.AddSeconds(-100 + queues.Count), DeclinedTime = now.AddMinutes(-5) };
            db.DriverQueues.Add(queue);
            queues.Add(queue);
        }
    }
    for (var i = 0; i < 4; i++)
    {
        var trip = new Trip { PickupLocationID = pickup.GoogleLocationID, DropoffLocationID = dropoff.GoogleLocationID,
            TripStatus = EnumTripStatus.MATCHING, TripType = EnumTripType.CASH, CalledTaxiSize = EnumTaxiSize.SMALL, CompanyID = companies[0].CompanyID };
        db.Trips.Add(trip);
        await db.SaveChangesAsync();
        db.CustomerQueues.Add(new CustomerQueue { TripID = trip.TripID, CreatedDateTime = now.AddSeconds(-20 + i) });
    }
    await db.SaveChangesAsync();
    return new([queues[0].DriverQueueID, queues[2].DriverQueueID, queues[1].DriverQueueID, queues[3].DriverQueueID], driverLogin, companyLogin.LoginUserID);
}
record Api(Process Process, HttpClient Client);
record Fixture(long[] QueueOrder, long DriverLogin, long CompanyLogin);
