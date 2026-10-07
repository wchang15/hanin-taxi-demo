using System.Security.Claims;
using KoreanTaxi.Data;
using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Services;

public sealed class HubGroupAuthorization(TaxiDbContext context)
{
    public async Task<string?> ResolveAsync(ClaimsPrincipal? principal, CancellationToken ct = default)
    {
        if (principal?.Identity?.IsAuthenticated != true ||
            !long.TryParse(principal.FindFirstValue(ClaimTypes.UserData), out var loginID)) return null;
        var user = await context.LoginUsers.AsNoTracking().SingleOrDefaultAsync(x => x.LoginUserID == loginID && x.IsActive, ct);
        if (user == null || !principal.IsInRole(user.Role.ToString())) return null;
        long? id = user.Role switch
        {
            EnumUserRole.DRIVER => await context.Drivers.Where(x => x.LoginUserID == loginID && x.IsArchived == null)
                .Select(x => (long?)x.DriverID).SingleOrDefaultAsync(ct),
            EnumUserRole.CUSTOMER => await context.Customers.Where(x => x.LoginUserID == loginID)
                .Select(x => (long?)x.CustomerID).SingleOrDefaultAsync(ct),
            EnumUserRole.COMPANY => await context.CompanyUsers.Where(x => x.LoginUserID == loginID)
                .Select(x => (long?)x.CompanyID).SingleOrDefaultAsync(ct),
            _ => null,
        };
        return id.HasValue ? user.Role.ToString().ToLowerInvariant() + id.Value : null;
    }
}
