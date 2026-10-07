using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Services;

public record DispatchOffer(long CompanyID, long DriverID, long DriverQueueID,
    long CustomerQueueID, long TripID, DispatchMatchScore Score);

public record DispatchAttempt(int WaitingDrivers, int WaitingCustomers, DispatchOffer? Offer);

// Both matching entry points share this singleton in the single-process demo.
// This is not a distributed lock or a substitute for relational transactions.
public sealed class CompanyDispatchService(IServiceScopeFactory scopeFactory, TimeProvider clock) : IDisposable
{
    private readonly SemaphoreSlim gate = new(1, 1);

    public async Task<DispatchAttempt> MatchNextAsync(CancellationToken cancellationToken = default)
    {
        await gate.WaitAsync(cancellationToken);
        try
        {
            // Read after acquiring the gate in a fresh context, never a stale queue snapshot.
            await using var scope = scopeFactory.CreateAsyncScope();
            var ctx = scope.ServiceProvider.GetRequiredService<TaxiDbContext>();
            var scoring = scope.ServiceProvider.GetRequiredService<IDispatchScoringService>();
            var drivers = await ctx.DriverQueues
                .Include(x => x.DriverQueueRejectedCustomerQueues)
                .Include(x => x.Driver).ThenInclude(x => x!.Company).ThenInclude(x => x!.CompanyOperatingStates)
                .Include(x => x.Driver).ThenInclude(x => x!.Taxi)
                .Where(x => x.QueueStatus == EnumQueueStatus.WAITING)
                .OrderBy(x => x.CreatedDateTime).ThenBy(x => x.DriverQueueID)
                .ToListAsync(cancellationToken);
            var customers = await ctx.CustomerQueues
                .Include(x => x.Trip).ThenInclude(x => x!.PickupLocation)
                .Include(x => x.Trip).ThenInclude(x => x!.DropoffLocation)
                .Where(x => x.QueueStatus == EnumQueueStatus.WAITING)
                .OrderBy(x => x.CreatedDateTime).ThenBy(x => x.CustomerQueueID)
                .ToListAsync(cancellationToken);
            var cursor = await ctx.DispatchCursors.SingleOrDefaultAsync(cancellationToken);
            var now = clock.GetUtcNow().UtcDateTime;
            var companies = drivers
                .Where(x => x.Driver?.Company != null && x.Driver.IsArchived == null)
                .GroupBy(x => x.Driver!.CompanyID)
                .OrderBy(x => cursor?.LastCompanyID is long last && x.Key <= last ? 1 : 0)
                .ThenBy(x => x.Key);

            foreach (var company in companies)
            {
                foreach (var driver in company)
                {
                    if ((now - driver.DeclinedTime).TotalSeconds < Constants.DRIVER_MATCH_IDLE_TIME) continue;
                    var candidate = customers
                        .Where(x => x.Trip?.TripStatus == EnumTripStatus.MATCHING && x.Trip.DriverID == null)
                        .Select(customer => new { Customer = customer, Score = scoring.ScoreCandidate(driver, customer, now) })
                        .Where(x => x.Score.IsEligible)
                        .OrderByDescending(x => x.Score.Score)
                        .ThenBy(x => x.Customer.CreatedDateTime).ThenBy(x => x.Customer.CustomerQueueID)
                        .FirstOrDefault();
                    if (candidate == null) continue;

                    driver.QueueStatus = EnumQueueStatus.PENDING;
                    driver.TripID = candidate.Customer.TripID;
                    driver.CustomerQueueID = candidate.Customer.CustomerQueueID;
                    candidate.Customer.QueueStatus = EnumQueueStatus.PENDING;
                    if (cursor == null)
                    {
                        cursor = new DispatchCursor();
                        ctx.DispatchCursors.Add(cursor);
                    }
                    cursor.LastCompanyID = company.Key;
                    await ctx.SaveChangesAsync(cancellationToken);

                    candidate.Score.Reasons.Insert(0, "Company rotation, then earliest eligible driver in that company's queue.");
                    return new(drivers.Count, customers.Count, new(company.Key, driver.DriverID,
                        driver.DriverQueueID, candidate.Customer.CustomerQueueID, candidate.Customer.TripID, candidate.Score));
                }
            }
            return new(drivers.Count, customers.Count, null);
        }
        finally
        {
            gate.Release();
        }
    }

    public void Dispose() => gate.Dispose();
}
