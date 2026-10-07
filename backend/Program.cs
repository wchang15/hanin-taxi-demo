using KoreanTaxi;
using KoreanTaxi.Data;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.Filters;
using System.ComponentModel;
using System.Text;
using System.Text.Json.Serialization;
using KoreanTaxi.Hubs;

Console.WriteLine("HaninTaxi process entered Program.cs.");
var builder = WebApplication.CreateBuilder(args);
Console.WriteLine("WebApplication builder created.");
var demoMode = builder.Configuration.GetValue<bool>("DemoMode");
var postgresDemo = builder.Configuration.GetValue<bool>("Demo:Postgres");
if (!demoMode)
{
    throw new InvalidOperationException("This portfolio snapshot only runs with DemoMode=true. It is not a production deployment.");
}
var jwtSigningKey = builder.Configuration["AppSettings:Token"];
if (string.IsNullOrWhiteSpace(jwtSigningKey))
{
    throw new InvalidOperationException("AppSettings:Token must be configured with a strong JWT signing key.");
}
Console.WriteLine($"HaninTaxi backend starting. DemoMode={demoMode}");

// Add services to the container.

var conn = builder.Configuration.GetConnectionString("defaultString");

//builder.Services.AddControllers();
builder.Services.AddScoped<DemoDatabaseTransactionFilter>();
builder.Services.AddScoped<DeferredHubNotifications>();
builder.Services.AddScoped<HubGroupAuthorization>();
builder.Services.AddControllers(options => options.Filters.AddService<DemoDatabaseTransactionFilter>())
    .AddJsonOptions(x => x.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles);
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IStripeService, StripeService>();
builder.Services.AddScoped<IBingService, BingService>();
builder.Services.AddScoped<ITwilioService, TwilioService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<ITollService, TollService>();
builder.Services.AddScoped<IGoogleService, GoogleService>();
builder.Services.AddScoped<IDispatchScoringService, DispatchScoringService>();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddSingleton<CompanyDispatchService>();
builder.Services.AddScoped<TaxiHub>();
builder.Services.AddHttpClient<ITollService, TollService>(client =>
{
    client.BaseAddress = new Uri("https://api.tollguru.com/v1/origin-destination-waypoints");
});
builder.Services.AddHttpClient<IGoogleService, GoogleService>();
builder.Services.AddScoped<TripManager>();
builder.Services.AddScoped<CustomerManager>();
builder.Services.AddScoped<DriverManager>();
builder.Services.AddScoped<LoginManager>();
builder.Services.AddScoped<CompanyManager>();
builder.Services.AddScoped<BackgroundManager>();
builder.Services.AddScoped<HubManager>();
if (builder.Configuration.GetValue<bool>("Dispatch:AutoMatch", true))
{
    builder.Services.AddHostedService<BackgroundWorkerServiceMatching>();
}
if (!demoMode)
{
    builder.Services.AddHostedService<BackgroundWorkerServiceCustomerQueue>();
    builder.Services.AddHostedService<BackgroundWorkerServiceRefund>();
}
builder.Services.AddHttpContextAccessor();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("oauth2", new OpenApiSecurityScheme
    {
        Description = "Standard Authorization header using the Bearer scheme (\"bearer {token}\")",
        In = ParameterLocation.Header,
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey
    });

    options.OperationFilter<SecurityRequirementsOperationFilter>();
});
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSigningKey)),
            ValidateIssuer = false,
            ValidateAudience = false
        };
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                if (context.Request.Path.StartsWithSegments("/Taxi") &&
                    string.IsNullOrEmpty(context.Request.Headers.Authorization))
                    context.Token = context.Request.Query["access_token"];
                return Task.CompletedTask;
            }
        };
    });

//builder.Services.AddCors(options => options.AddPolicy(name: "NgOrigins",
//    builder =>
//    {
//        builder.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
//    }));

//builder.Services.AddCors(options =>
//{
//    options.AddPolicy("AllowAll",
//        builder =>
//        {
//            builder
//            .AllowAnyOrigin()
//            .AllowAnyMethod()
//            .AllowAnyHeader();
//        });
//});

builder.Services.AddCors(options => options.AddPolicy(name: "corsapp", policy =>
{
    policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
}));

builder.Services.AddDataProtection().UseEphemeralDataProtectionProvider();
if (!postgresDemo)
{
    Console.WriteLine("Using in-memory demo database.");
    builder.Services.AddDbContext<TaxiDbContext>(options => options.UseInMemoryDatabase("HaninTaxiDemo"));
}
else
{
    conn = DemoDatabase.Validate(builder.Configuration.GetConnectionString("DemoPostgres"));
    Console.WriteLine("Using isolated PostgreSQL demo database. Real integrations remain disabled.");
    builder.Services.AddDbContext<TaxiDbContext>(options => options.UseNpgsql(conn).UseLowerCaseNamingConvention());
}

//builder.Services.AddDbContext<TaxiDbContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("defaultString")));
//builder.Services.AddDbContext<TaxiDbContext>(options => options.UseLazyLoadingProxies().UseSqlServer(builder.Configuration.GetConnectionString("defaultString")));

builder.Services.AddSignalR(e =>
{
    e.MaximumReceiveMessageSize = 102400000;
    e.KeepAliveInterval = TimeSpan.FromMinutes(5);
    e.ClientTimeoutInterval = TimeSpan.FromMinutes(10);
});

Console.WriteLine("Building web application.");
var app = builder.Build();
Console.WriteLine("Web application built.");

if (demoMode)
{
    using var demoScope = app.Services.CreateScope();
    var demoContext = demoScope.ServiceProvider.GetRequiredService<TaxiDbContext>();
    if (postgresDemo)
    {
        await demoContext.Database.OpenConnectionAsync();
        try
        {
            // Serialize fresh-schema setup and seed across simultaneous startups.
            await demoContext.Database.ExecuteSqlRawAsync("SELECT pg_advisory_lock(726104032)");
            await demoContext.Database.EnsureCreatedAsync();
            await using var transaction = await DispatchTransaction.BeginAsync(demoContext, CancellationToken.None);
            SeedDemoData(demoContext);
            await transaction!.CommitAsync();
        }
        finally
        {
            await demoContext.Database.ExecuteSqlRawAsync("SELECT pg_advisory_unlock(726104032)");
            await demoContext.Database.CloseConnectionAsync();
        }
    }
    else SeedDemoData(demoContext);
}

// Configure the HTTP request pipeline.
// if (app.Environment.IsDevelopment())
// {

app.UseSwaggerAuthorized();
app.UseSwagger();
app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "SecureSwagger v1"));
// }
app.UseRouting();

app.UseCors("corsapp");



if (!demoMode)
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.MapHub<TaxiHub>("/Taxi", options => options.CloseOnAuthenticationExpiration = true);

if (!demoMode)
{
    using (var scope = app.Services.CreateScope())
    {
        var services = scope.ServiceProvider;

        var context = services.GetRequiredService<TaxiDbContext>();
        if (context.Database.GetPendingMigrations().Any())
        {
            context.Database.Migrate();
        }
    }
}

Console.WriteLine("Starting web server.");
app.Run();

static void SeedDemoData(TaxiDbContext context)
{
    if (context.LoginUsers.Any())
    {
        return;
    }

    var companyUser = new LoginUser
    {
        Username = "demo_company",
        Password = "demo1234",
        Role = KoreanTaxi.Models.Enums.EnumUserRole.COMPANY,
        IsActive = true,
    };
    var driverUser = new LoginUser
    {
        Username = "demo_driver",
        Password = "demo1234",
        Role = KoreanTaxi.Models.Enums.EnumUserRole.DRIVER,
        IsActive = true,
    };
    var customerUser = new LoginUser
    {
        Username = "demo_customer",
        Password = "demo1234",
        Role = KoreanTaxi.Models.Enums.EnumUserRole.CUSTOMER,
        IsActive = true,
    };

    context.LoginUsers.AddRange(companyUser, driverUser, customerUser);
    context.SaveChanges();

    var company = new Company
    {
        Name = "Hanin Taxi Demo",
        PhoneNumber = "2015550100",
        ContactName = "Demo Dispatcher",
        Address1 = "100 Main St",
        City = "Fort Lee",
        State = "NJ",
        Zip = "07024",
        Latitude = 40.8509,
        Longitude = -73.9701,
        TimeZone = KoreanTaxi.Models.Enums.EnumTimeZone.Eastern,
    };
    context.Companies.Add(company);
    context.SaveChanges();

    var demoOperatingStates = new[]
    {
        KoreanTaxi.Models.Enums.EnumState.NJ,
        KoreanTaxi.Models.Enums.EnumState.NY,
        KoreanTaxi.Models.Enums.EnumState.NYC,
    };
    context.CompanyOperatingStates.AddRange(
        demoOperatingStates.Select(state => new CompanyOperatingState
        {
            CompanyID = company.CompanyID,
            FromState = state,
            ToState = null,
        }));

    context.CompanyUsers.Add(new CompanyUser
    {
        CompanyID = company.CompanyID,
        LoginUserID = companyUser.LoginUserID,
        Name = "Demo Dispatcher",
    });

    var driver = new Driver
    {
        FirstName = "Demo",
        LastName = "Driver",
        Email = "demo.driver@example.com",
        PhoneNumber = "2015550102",
        CompanyID = company.CompanyID,
        LoginUserID = driverUser.LoginUserID,
        DriverNumber = 101,
        TLCApproved = true,
        IsAppTaxi = true,
        Language = KoreanTaxi.Models.Enums.EnumLanguage.ENGLISH,
        Map = "Google",
    };
    context.Drivers.Add(driver);

    var customer = new Customer
    {
        FirstName = "Demo",
        LastName = "Customer",
        Email = "demo.customer@example.com",
        PhoneNumber = "2015550101",
        LoginUserID = customerUser.LoginUserID,
        IsVerified = true,
        StripeCustomerID = "demo_customer_seed",
        Language = KoreanTaxi.Models.Enums.EnumLanguage.ENGLISH,
    };
    context.Customers.Add(customer);
    context.SaveChanges();

    context.Taxis.Add(new Taxi
    {
        Color = KoreanTaxi.Models.Enums.EnumTaxiColor.BLACK,
        Make = KoreanTaxi.Models.Enums.EnumTaxiMake.TOYOTA,
        Model = "Camry",
        LicensePlate = "T1234C",
        Size = KoreanTaxi.Models.Enums.EnumTaxiSize.SMALL,
        DriverID = driver.DriverID,
    });
    context.SaveChanges();
}
