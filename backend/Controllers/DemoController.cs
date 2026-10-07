using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KoreanTaxi.Controllers;

[ApiController]
[Route("api/[controller]")]
[AllowAnonymous]
public class DemoController(IConfiguration configuration, CompanyDispatchService dispatch) : ControllerBase
{
    [HttpGet("Status")]
    public IActionResult Status()
    {
        if (!configuration.GetValue<bool>("DemoMode")) return NotFound();
        return Ok(new { demoMode = true, persistence = "in-memory", externalPayments = false });
    }

    [HttpPost("RunDispatch")]
    public async Task<IActionResult> RunDispatch(CancellationToken cancellationToken)
    {
        if (!configuration.GetValue<bool>("DemoMode")) return NotFound();
        var attempt = await dispatch.MatchNextAsync(cancellationToken);
        var offer = attempt.Offer;
        if (offer == null)
        {
            return Ok(new { matched = false, attempt.WaitingDrivers, attempt.WaitingCustomers });
        }
        return Ok(new
        {
            matched = true,
            policy = "company-round-robin",
            offer.CompanyID,
            offer.DriverQueueID,
            offer.CustomerQueueID,
            offer.TripID,
            offer.Score.Score,
            offer.Score.PickupDistanceMiles,
            offer.Score.CustomerWaitMinutes,
            offer.Score.Reasons,
        });
    }
}
