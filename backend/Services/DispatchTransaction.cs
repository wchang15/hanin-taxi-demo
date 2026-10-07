using System.Data;
using KoreanTaxi.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace KoreanTaxi.Services;

public static class DispatchTransaction
{
    // One fleet-wide lock preserves the global company cursor. This deliberately
    // favors correctness over throughput; every demo API writer uses this key.
    public static async Task<IDbContextTransaction?> BeginAsync(TaxiDbContext context, CancellationToken ct)
    {
        if (!context.Database.IsNpgsql()) return null;
        var transaction = await context.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);
        try
        {
            await context.Database.ExecuteSqlRawAsync("SET LOCAL lock_timeout = '5s'", ct);
            await context.Database.ExecuteSqlRawAsync("SET LOCAL statement_timeout = '8s'", ct);
            await context.Database.ExecuteSqlRawAsync("SET LOCAL idle_in_transaction_session_timeout = '10s'", ct);
            await context.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(726104031)", ct);
            return transaction;
        }
        catch
        {
            await transaction.DisposeAsync();
            throw;
        }
    }
}
