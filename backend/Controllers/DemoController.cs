using KoreanTaxi.Data;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class DemoController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IConfiguration configuration;
        private readonly IDispatchScoringService dispatchScoringService;

        public DemoController(TaxiDbContext ctx, IConfiguration configuration, IDispatchScoringService dispatchScoringService)
        {
            this.ctx = ctx;
            this.configuration = configuration;
            this.dispatchScoringService = dispatchScoringService;
        }

        [HttpGet("Status")]
        public IActionResult Status()
        {
            if (!configuration.GetValue<bool>("DemoMode")) return NotFound();
            return Ok(new { demoMode = true, persistence = "in-memory", externalPayments = false });
        }

        [HttpPost("RunDispatch")]
        public async Task<IActionResult> RunDispatch()
        {
            if (!configuration.GetValue<bool>("DemoMode"))
            {
                return NotFound();
            }

            var driverQueues = await ctx.DriverQueues
                .Include(x => x.DriverQueueRejectedCustomerQueues)
                .Include(x => x.Driver)
                    .ThenInclude(x => x.Company)
                    .ThenInclude(x => x.CompanyOperatingStates)
                .Include(x => x.Driver)
                    .ThenInclude(x => x.Taxi)
                .Where(x => x.QueueStatus == EnumQueueStatus.WAITING)
                .OrderBy(x => x.CreatedDateTime)
                .ToListAsync();

            var customerQueues = await ctx.CustomerQueues
                .Include(x => x.Trip)
                    .ThenInclude(x => x.PickupLocation)
                .Include(x => x.Trip)
                    .ThenInclude(x => x.DropoffLocation)
                .Where(x => x.QueueStatus == EnumQueueStatus.WAITING)
                .OrderBy(x => x.CreatedDateTime)
                .ToListAsync();

            var nowUtc = DateTime.UtcNow;
            var candidates = driverQueues
                .SelectMany(driverQueue => customerQueues.Select(customerQueue => new
                {
                    DriverQueue = driverQueue,
                    CustomerQueue = customerQueue,
                    Score = dispatchScoringService.ScoreCandidate(driverQueue, customerQueue, nowUtc),
                }))
                .ToList();

            var bestCandidate = candidates
                .Where(x => x.Score.IsEligible)
                .OrderByDescending(x => x.Score.Score)
                .ThenBy(x => x.CustomerQueue.CreatedDateTime)
                .ThenBy(x => x.DriverQueue.CreatedDateTime)
                .FirstOrDefault();

            if (bestCandidate == null)
            {
                return Ok(new
                {
                    matched = false,
                    waitingDrivers = driverQueues.Count,
                    waitingCustomers = customerQueues.Count,
                    candidates = candidates.Select(x => new
                    {
                        driverQueueID = x.DriverQueue.DriverQueueID,
                        customerQueueID = x.CustomerQueue.CustomerQueueID,
                        tripID = x.CustomerQueue.TripID,
                        x.Score.IsEligible,
                        x.Score.Score,
                        x.Score.Rejections,
                    }),
                });
            }

            bestCandidate.DriverQueue.QueueStatus = EnumQueueStatus.PENDING;
            bestCandidate.DriverQueue.TripID = bestCandidate.CustomerQueue.TripID;
            bestCandidate.DriverQueue.CustomerQueueID = bestCandidate.CustomerQueue.CustomerQueueID;
            bestCandidate.CustomerQueue.QueueStatus = EnumQueueStatus.PENDING;
            await ctx.SaveChangesAsync();

            return Ok(new
            {
                matched = true,
                driverQueueID = bestCandidate.DriverQueue.DriverQueueID,
                customerQueueID = bestCandidate.CustomerQueue.CustomerQueueID,
                tripID = bestCandidate.CustomerQueue.TripID,
                bestCandidate.Score.Score,
                bestCandidate.Score.PickupDistanceMiles,
                bestCandidate.Score.CustomerWaitMinutes,
                bestCandidate.Score.Reasons,
            });
        }
    }
}
