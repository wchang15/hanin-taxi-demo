using System.Security.Claims;
using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace HaninTaxi.Tests;

public class RealtimeSafetyTests
{
    [Theory]
    [InlineData(EnumUserRole.DRIVER, "driver20")]
    [InlineData(EnumUserRole.CUSTOMER, "customer30")]
    [InlineData(EnumUserRole.COMPANY, "company40")]
    public async Task Group_is_derived_from_database_identity(EnumUserRole role, string expected)
    {
        using var db = Seed(role);
        Assert.Equal(expected, await new HubGroupAuthorization(db).ResolveAsync(Principal(role)));
    }

    [Theory]
    [InlineData("anonymous")]
    [InlineData("missing-id")]
    [InlineData("malformed-id")]
    [InlineData("wrong-role")]
    [InlineData("inactive")]
    [InlineData("archived")]
    [InlineData("missing-profile")]
    public async Task Invalid_or_inactive_identity_cannot_subscribe(string failure)
    {
        using var db = Seed(EnumUserRole.DRIVER);
        var principal = Principal(EnumUserRole.DRIVER);
        switch (failure)
        {
            case "anonymous": principal = new ClaimsPrincipal(new ClaimsIdentity()); break;
            case "missing-id": principal = new ClaimsPrincipal(new ClaimsIdentity([], "test")); break;
            case "malformed-id": principal = Principal(EnumUserRole.DRIVER, "bad"); break;
            case "wrong-role": principal = Principal(EnumUserRole.COMPANY); break;
            case "inactive": db.LoginUsers.Single().IsActive = false; break;
            case "archived": db.Drivers.Single().IsArchived = DateTime.UtcNow; break;
            case "missing-profile": db.Drivers.RemoveRange(db.Drivers); break;
        }
        await db.SaveChangesAsync();
        Assert.Null(await new HubGroupAuthorization(db).ResolveAsync(principal));
    }

    [Fact]
    public async Task Deferred_events_wait_until_commit_and_flush_once_in_order()
    {
        var delivery = new DeferredHubNotifications(NullLogger<DeferredHubNotifications>.Instance);
        var sent = new List<int>();
        delivery.Begin();
        await delivery.SendAsync(() => { sent.Add(1); return Task.CompletedTask; });
        await delivery.SendAsync(() => { sent.Add(2); return Task.CompletedTask; });
        Assert.Empty(sent);
        await delivery.FlushAsync();
        await delivery.FlushAsync();
        Assert.Equal(new[] { 1, 2 }, sent);
    }

    [Fact]
    public async Task Rollback_discards_pending_events()
    {
        var delivery = new DeferredHubNotifications(NullLogger<DeferredHubNotifications>.Instance);
        var sent = false;
        delivery.Begin();
        await delivery.SendAsync(() => { sent = true; return Task.CompletedTask; });
        delivery.Discard();
        await delivery.FlushAsync();
        Assert.False(sent);
    }

    [Fact]
    public async Task Post_commit_delivery_failure_does_not_fail_command_or_block_later_events()
    {
        var delivery = new DeferredHubNotifications(NullLogger<DeferredHubNotifications>.Instance);
        var sent = false;
        delivery.Begin();
        await delivery.SendAsync(() => throw new IOException("Connection lost"));
        await delivery.SendAsync(() => { sent = true; return Task.CompletedTask; });
        await delivery.FlushAsync();
        Assert.True(sent);
    }

    [Fact]
    public async Task In_memory_nontransactional_path_delivers_immediately()
    {
        var delivery = new DeferredHubNotifications(NullLogger<DeferredHubNotifications>.Instance);
        var sent = false;
        await delivery.SendAsync(() => { sent = true; return Task.CompletedTask; });
        Assert.True(sent);
    }

    private static ClaimsPrincipal Principal(EnumUserRole role, string id = "10") =>
        new(new ClaimsIdentity([new(ClaimTypes.UserData, id), new(ClaimTypes.Role, role.ToString())], "test"));

    private static TaxiDbContext Seed(EnumUserRole role)
    {
        var db = new TaxiDbContext(new DbContextOptionsBuilder<TaxiDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        db.LoginUsers.Add(new LoginUser { LoginUserID = 10, Role = role, IsActive = true });
        db.Drivers.Add(new Driver { DriverID = 20, LoginUserID = 10, FirstName = "Test", LastName = "Driver", PhoneNumber = "2015550100" });
        db.Customers.Add(new Customer { CustomerID = 30, LoginUserID = 10, FirstName = "Test", LastName = "Rider", PhoneNumber = "2015550101", StripeCustomerID = "synthetic" });
        db.CompanyUsers.Add(new CompanyUser { CompanyUserID = 50, LoginUserID = 10, CompanyID = 40, Name = "Operator" });
        db.SaveChanges();
        return db;
    }
}
