using KoreanTaxi.Controllers;
using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace HaninTaxi.Tests;

public class CompanyDispatchTests
{
    [Fact]
    public async Task Alternates_companies_then_preserves_each_driver_queue()
    {
        await using var f = new Fixture();
        await f.Seed();
        var offers = await f.Drain();
        Assert.Equal(new long[] { 11, 21, 12, 22 }, offers.Select(x => x.DriverID));
        Assert.Equal(4, offers.Select(x => x.CustomerQueueID).Distinct().Count());
        using var ctx = f.Context();
        Assert.All(ctx.DriverQueues, x => Assert.Equal(EnumQueueStatus.PENDING, x.QueueStatus));
        Assert.All(ctx.CustomerQueues, x => Assert.Equal(EnumQueueStatus.PENDING, x.QueueStatus));
        Assert.Equal(20, ctx.DispatchCursors.Single().LastCompanyID);
    }

    [Fact]
    public async Task Cursor_survives_service_recreation_with_the_same_database()
    {
        await using var f = new Fixture();
        await f.Seed();
        Assert.Equal(11, (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!.DriverID);
        using var restarted = new CompanyDispatchService(f.Services.GetRequiredService<IServiceScopeFactory>(), f.Clock);
        Assert.Equal(21, (await restarted.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!.DriverID);
    }

    [Fact]
    public async Task Nearest_car_cannot_jump_company_or_driver_order()
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            var first = ctx.DriverQueues.Single(x => x.DriverID == 11);
            first.Latitude += 0.01;
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        Assert.Equal(11, (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!.DriverID);
    }

    [Fact]
    public async Task Empty_company_is_skipped_and_rotation_wraps()
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            ctx.DriverQueues.RemoveRange(ctx.DriverQueues.Where(x => x.DriverID >= 20));
            ctx.DispatchCursors.Add(new() { LastCompanyID = 20 });
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        Assert.Equal(new long[] { 11, 12 }, (await f.Drain()).Select(x => x.DriverID));
    }

    [Fact]
    public async Task Cooldown_skips_head_without_removing_its_position()
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            ctx.DriverQueues.Single(x => x.DriverID == 11).DeclinedTime = f.Clock.Now;
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        Assert.Equal(12, (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!.DriverID);
        f.Clock.Now = f.Clock.Now.AddSeconds(2);
        Assert.Equal(21, (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!.DriverID);
        Assert.Equal(11, (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!.DriverID);
    }

    [Theory]
    [InlineData("region")]
    [InlineData("airport")]
    [InlineData("archived")]
    [InlineData("non-app")]
    [InlineData("rejected")]
    [InlineData("unavailable")]
    [InlineData("size")]
    public async Task Ineligible_company_head_does_not_block_other_drivers(string reason)
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            var driver = ctx.Drivers.Include(x => x.Company).ThenInclude(x => x!.CompanyOperatingStates)
                .Single(x => x.DriverID == 11);
            var queue = ctx.DriverQueues.Single(x => x.DriverID == 11);
            switch (reason)
            {
                case "region":
                    ctx.CompanyOperatingStates.RemoveRange(driver.Company!.CompanyOperatingStates!);
                    break;
                case "airport": driver.TLCApproved = false; break;
                case "archived": driver.IsArchived = f.Clock.Now; break;
                case "non-app": driver.IsAppTaxi = false; break;
                case "unavailable": queue.QueueStatus = EnumQueueStatus.ACCEPTED; break;
                case "size":
                    foreach (var trip in ctx.Trips) trip.CalledTaxiSize = EnumTaxiSize.LARGE;
                    ctx.Taxis.Single(x => x.DriverID == 21).Size = EnumTaxiSize.LARGE;
                    break;
                case "rejected":
                    foreach (var customer in ctx.CustomerQueues)
                        ctx.DriverQueueRejectedCustomerQueues.Add(new() { DriverQueueID = queue.DriverQueueID, CustomerQueueID = customer.CustomerQueueID });
                    break;
            }
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        var offer = (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!;
        Assert.Equal(reason is "region" or "size" ? 21 : 12, offer.DriverID);
    }

    [Fact]
    public async Task Company_specific_request_never_goes_to_another_company()
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            foreach (var customer in ctx.CustomerQueues) customer.CompanyID = 20;
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        Assert.All(await f.Drain(), offer => Assert.Equal(20, offer.CompanyID));
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task No_match_does_not_advance_or_create_cursor(bool existingCursor)
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            foreach (var customer in ctx.CustomerQueues) customer.QueueStatus = EnumQueueStatus.ACCEPTED;
            if (existingCursor) ctx.DispatchCursors.Add(new() { LastCompanyID = 10 });
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        Assert.Null((await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer);
        using var check = f.Context();
        Assert.Equal(existingCursor ? 10L : null, check.DispatchCursors.SingleOrDefault()?.LastCompanyID);
    }

    [Fact]
    public async Task Stale_waiting_queue_cannot_reoffer_assigned_trip()
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            foreach (var trip in ctx.Trips) trip.DriverID = 99;
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        Assert.Null((await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer);
    }

    [Fact]
    public async Task Equal_timestamps_use_queue_ID_as_a_stable_tiebreaker()
    {
        await using var f = new Fixture();
        await f.Seed();
        using (var ctx = f.Context())
        {
            foreach (var queue in ctx.DriverQueues) queue.CreatedDateTime = f.Clock.Now;
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }
        Assert.Equal(new long[] { 11, 21, 12, 22 }, (await f.Drain()).Select(x => x.DriverID));
    }

    [Fact]
    public async Task Concurrent_invocations_cannot_offer_a_driver_or_customer_twice()
    {
        await using var f = new Fixture();
        await f.Seed();
        f.Interceptor.PauseNext = true;
        var first = f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken);
        await f.Interceptor.Entered.Task.WaitAsync(TimeSpan.FromSeconds(10), TestContext.Current.CancellationToken);
        var others = Enumerable.Range(0, 7).Select(_ => f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).ToArray();
        Assert.All(others, task => Assert.False(task.IsCompleted));
        f.Interceptor.Release.TrySetResult();
        var results = await Task.WhenAll(new[] { first }.Concat(others));
        var offers = results.Where(x => x.Offer != null).Select(x => x.Offer!).ToList();
        Assert.Equal(4, offers.Count);
        Assert.Equal(4, offers.Select(x => x.DriverID).Distinct().Count());
        Assert.Equal(4, offers.Select(x => x.CustomerQueueID).Distinct().Count());
    }

    [Fact]
    public async Task Save_failure_leaves_cursor_and_queues_unchanged_and_releases_gate()
    {
        await using var f = new Fixture();
        await f.Seed();
        f.Interceptor.FailNext = true;
        await Assert.ThrowsAsync<InvalidOperationException>(() => f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken));
        using (var ctx = f.Context())
        {
            Assert.Empty(ctx.DispatchCursors);
            Assert.All(ctx.DriverQueues, x => Assert.Equal(EnumQueueStatus.WAITING, x.QueueStatus));
            Assert.All(ctx.CustomerQueues, x => Assert.Equal(EnumQueueStatus.WAITING, x.QueueStatus));
        }
        Assert.Equal(11, (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken).WaitAsync(TimeSpan.FromSeconds(10), TestContext.Current.CancellationToken)).Offer!.DriverID);
    }

    [Fact]
    public async Task Cancelled_waiter_does_not_consume_a_turn_or_unlock_another_call()
    {
        await using var f = new Fixture();
        await f.Seed();
        f.Interceptor.PauseNext = true;
        var first = f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken);
        await f.Interceptor.Entered.Task.WaitAsync(TimeSpan.FromSeconds(10), TestContext.Current.CancellationToken);
        using var cancellation = new CancellationTokenSource();
        var waiting = f.Dispatch.MatchNextAsync(cancellation.Token);
        cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => waiting);
        var next = f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken);
        Assert.False(next.IsCompleted);
        f.Interceptor.Release.TrySetResult();
        Assert.Equal(11, (await first).Offer!.DriverID);
        Assert.Equal(21, (await next).Offer!.DriverID);
    }

    [Fact]
    public async Task Demo_endpoint_consumes_the_same_cursor_as_the_worker_service()
    {
        await using var f = new Fixture();
        await f.Seed();
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> { ["DemoMode"] = "true" }).Build();
        var controller = new DemoController(config, f.Dispatch);
        Assert.IsType<OkObjectResult>(await controller.RunDispatch(TestContext.Current.CancellationToken));
        Assert.Equal(21, (await f.Dispatch.MatchNextAsync(TestContext.Current.CancellationToken)).Offer!.DriverID);
    }

    private sealed class Clock : TimeProvider
    {
        public DateTime Now { get; set; } = new(2026, 10, 6, 12, 0, 0, DateTimeKind.Utc);
        public override DateTimeOffset GetUtcNow() => new(Now);
    }

    private sealed class SaveControl : SaveChangesInterceptor
    {
        public bool FailNext { get; set; }
        public bool PauseNext { get; set; }
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);

        public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
            DbContextEventData eventData, InterceptionResult<int> result, CancellationToken cancellationToken = default)
        {
            if (PauseNext)
            {
                PauseNext = false;
                Entered.TrySetResult();
                await Release.Task.WaitAsync(cancellationToken);
            }
            if (FailNext)
            {
                FailNext = false;
                throw new InvalidOperationException("Injected pre-save failure");
            }
            return result;
        }
    }

    private sealed class Fixture : IAsyncDisposable
    {
        public Clock Clock { get; } = new();
        public SaveControl Interceptor { get; } = new();
        public ServiceProvider Services { get; }
        private readonly DbContextOptions<TaxiDbContext> options;
        public CompanyDispatchService Dispatch => Services.GetRequiredService<CompanyDispatchService>();

        public Fixture()
        {
            options = new DbContextOptionsBuilder<TaxiDbContext>()
                .UseInMemoryDatabase(Guid.NewGuid().ToString()).AddInterceptors(Interceptor).Options;
            Services = new ServiceCollection()
                .AddScoped(_ => new TaxiDbContext(options))
                .AddScoped<IDispatchScoringService, DispatchScoringService>()
                .AddSingleton<TimeProvider>(Clock).AddSingleton<CompanyDispatchService>()
                .BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true });
        }

        public TaxiDbContext Context() => new(options);

        public async Task Seed()
        {
            using var ctx = Context();
            foreach (var companyID in new long[] { 10, 20 })
            {
                var company = new Company
                {
                    CompanyID = companyID, Name = $"Company {companyID}", PhoneNumber = "demo", ContactName = "Demo",
                    CompanyOperatingStates = new List<CompanyOperatingState> { new() { FromState = EnumState.NJ, ToState = EnumState.NY } }
                };
                for (var position = 1; position <= 2; position++)
                {
                    var id = companyID + position;
                    ctx.DriverQueues.Add(new DriverQueue
                    {
                        DriverQueueID = id, DriverID = id, Latitude = 40.8509, Longitude = -73.9701,
                        CreatedDateTime = Clock.Now.AddMinutes(-100 + id), DeclinedTime = Clock.Now.AddMinutes(-1),
                        Driver = new Driver
                        {
                            DriverID = id, FirstName = "Demo", LastName = id.ToString(), PhoneNumber = "demo",
                            Company = company, CompanyID = companyID, IsAppTaxi = true, TLCApproved = true,
                            Taxi = new Taxi { Size = EnumTaxiSize.SMALL, Model = "Demo", LicensePlate = "demo" }
                        }
                    });
                }
            }
            for (var id = 1; id <= 4; id++)
            {
                ctx.CustomerQueues.Add(new CustomerQueue
                {
                    CustomerQueueID = id, CreatedDateTime = Clock.Now,
                    Trip = new Trip
                    {
                        TripStatus = EnumTripStatus.MATCHING, CalledTaxiSize = EnumTaxiSize.SMALL,
                        PickupLocation = new GoogleLocation { Latitude = 40.8509, Longitude = -73.9701, State = EnumState.NJ },
                        DropoffLocation = new GoogleLocation { State = EnumState.NY, LocationType = EnumLocationType.AIRPORT }
                    }
                });
            }
            await ctx.SaveChangesAsync(TestContext.Current.CancellationToken);
        }

        public async Task<List<DispatchOffer>> Drain()
        {
            var offers = new List<DispatchOffer>();
            for (var i = 0; i < 8; i++)
            {
                var attempt = await Dispatch.MatchNextAsync(TestContext.Current.CancellationToken);
                if (attempt.Offer == null) return offers;
                offers.Add(attempt.Offer);
            }
            throw new InvalidOperationException("Dispatcher did not exhaust fixture queues.");
        }

        public ValueTask DisposeAsync() => Services.DisposeAsync();
    }
}
