using KoreanTaxi.Data;
using KoreanTaxi.Helper;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = nameof(EnumUserRole.DRIVER))]
    public class DriverQueueController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;
        private readonly DriverManager driverManager;
        private readonly TripManager tripManager;
        private readonly HubManager hubManager;

        public DriverQueueController(TaxiDbContext ctx, IUserService userService, DriverManager driverManager, TripManager tripManager, HubManager hubManager)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.driverManager = driverManager;
            this.tripManager = tripManager;
            this.hubManager = hubManager;
        }


        [HttpPost("EnqueueDriver")]
        public async Task<IActionResult> AddDriverToQueue(LatLng loc)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var existingDriverQueue = await ctx.DriverQueues.Where(x => x.DriverID == driver.DriverID).FirstOrDefaultAsync();
            if (existingDriverQueue != null)
            {
                // When Customer Canceled
                existingDriverQueue.TripID = null;
                existingDriverQueue.QueueStatus = EnumQueueStatus.WAITING;
                existingDriverQueue.CustomerQueueID = null;
                existingDriverQueue.CreatedDateTime = DateTime.UtcNow;
                existingDriverQueue.DeclinedTime = DateTime.UtcNow;
                await ctx.SaveChangesAsync();
                return Ok(existingDriverQueue);
            } 
            else
            {
                var driverQueue = await driverManager.AddDriverToQueue(driver.DriverID, loc);
                return Ok(driverQueue);
            }
        }

        //This will get called every 5 second from the client
        [HttpGet("GetDriverQueueStatus")]
        public async Task<IActionResult> GetDriverQueueStatus()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var driverQueue = await ctx.DriverQueues.Where(x => x.DriverID == driver.DriverID).FirstOrDefaultAsync();
            if (driverQueue == null) return Ok("NoQueue"); // Not in a queue

            if (driverQueue.QueueStatus == EnumQueueStatus.CUSTOMERCANCELED) return Ok("customercancel");
            if (driverQueue.QueueStatus == EnumQueueStatus.COMPANYCANCELED) return Ok("companycancel");
            if (driverQueue.TripID == null) return Ok("waiting"); //Waiting to Match a new trip

            var trip = await tripManager.GetTripByID(driverQueue.TripID.Value);
            if (trip == null) return NotFound("Trip Not Found");

            var tripReturn = await tripManager.TripReturnForDriver(trip);

            return Ok(tripReturn);

        }

        [HttpPost("UpdateDriverQueueLocation")]
        public async Task<IActionResult> UpdateDriverQueueLocation(LatLng loc)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var driverQueue = await ctx.DriverQueues.Where(x => x.DriverID == driver.DriverID).FirstOrDefaultAsync();
            if (driverQueue == null) return Ok("NoQueue"); // Not in a queue

            driverQueue.Latitude = loc.Latitude;
            driverQueue.Longitude = loc.Longitude;

            await ctx.SaveChangesAsync();

            var customerQueue = await ctx.CustomerQueues.Where(x => x.TripID == driverQueue.TripID && x.QueueStatus == EnumQueueStatus.ACCEPTED).FirstOrDefaultAsync();
            if (customerQueue != null)
            {
                var latlng = new LatLng(loc.Latitude, loc.Longitude);
                await hubManager.SendToClient($"{Constants.CUSTOMER}{customerQueue.CustomerID}", Constants.UPDATEDRIVERLOCATION, EnumTripStatus.PICKINGUPCUSTOMER, latlng);
            }

            return Ok("Success");

        }

        [HttpPost("MatchTrip")]
        public async Task<IActionResult> MatchTrip()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var driverQueue = await ctx.DriverQueues.Where(x => x.DriverID == driver.DriverID && x.QueueStatus == EnumQueueStatus.PENDING).FirstOrDefaultAsync();
            if (driverQueue == null) return BadRequest("Driver doesn't have a pending queue.");

            var customerQueue = await ctx.CustomerQueues.Where(x => x.TripID == driverQueue.TripID && x.QueueStatus == EnumQueueStatus.PENDING).FirstOrDefaultAsync();
            if (customerQueue == null) return BadRequest("Customer Queue does not exist.");

            var trip = await ctx.Trips.Include(x => x.PickupLocation).ThenInclude(x => x.CompanyGoogleLocation).Where(x => x.TripID == driverQueue.TripID && x.DriverID == null && x.TripStatus == EnumTripStatus.MATCHING).FirstOrDefaultAsync();
            if (trip == null) return BadRequest("Trip does not exist.");

            trip.DriverID = driver.DriverID;
            trip.TripStatus = EnumTripStatus.PICKINGUPCUSTOMER;
            customerQueue.QueueStatus = EnumQueueStatus.ACCEPTED;
            driverQueue.QueueStatus = EnumQueueStatus.ACCEPTED;
            await ctx.SaveChangesAsync();

            if (customerQueue.CustomerID != null)
            {
                var tripReturnForCutomer = await tripManager.TripReturnForCustomer(trip);
                await hubManager.SendToClient($"{Constants.CUSTOMER}{customerQueue.CustomerID}", Constants.MATCH, trip.TripStatus, tripReturnForCutomer);
            }
            else if (customerQueue.CompanyID != null) 
            {
                var tripReturnForCompany = await tripManager.GetCurrentTripCompany(trip);
                await hubManager.SendToClient($"{Constants.COMPANY}{customerQueue.CompanyID}", Constants.MATCH, tripReturnForCompany.TripStatus, tripReturnForCompany);
            }

            if (trip.TripType == EnumTripType.ALCOHOL1 || trip.TripType == EnumTripType.ALCOHOL2)
            {
                await tripManager.MatchAlcoholTrip(trip);
            }

            return Ok("Success");
        }

        [HttpPost("DeclinedQueue")]
        public async Task<IActionResult> IncreaseDeclined()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var queue = await ctx.DriverQueues.Where(x => x.DriverID == driver.DriverID && x.QueueStatus == EnumQueueStatus.PENDING).FirstOrDefaultAsync();
            if (queue == null) return NotFound("Queue Not Found");

            var customerQueue = await ctx.CustomerQueues.Where(x => x.TripID == queue.TripID && x.QueueStatus == EnumQueueStatus.PENDING).FirstOrDefaultAsync();
            if (customerQueue != null)
            {
                customerQueue.QueueStatus = EnumQueueStatus.WAITING;
                ctx.SaveChanges();
            }

            if (queue.DeclinedCount == 3)
            {
                await driverManager.RemoveFromQueue(driver.DriverID);
                return Ok(false);
            }
            else
            {
                queue.DeclinedCount += 1;
                queue.QueueStatus = EnumQueueStatus.WAITING;
                queue.DeclinedTime = DateTime.UtcNow;
                queue.TripID = null;
                queue.CustomerQueueID = null;

                var driverQueueRejectedCustomerQueue = new DriverQueueRejectedCustomerQueue() 
                { 
                    DriverQueueID = queue.DriverQueueID, 
                    CustomerQueueID = customerQueue?.CustomerQueueID ?? 0 ,
                };
                ctx.DriverQueueRejectedCustomerQueues.Add(driverQueueRejectedCustomerQueue);

                await ctx.SaveChangesAsync();
                return Ok(true);
            }
        }

        [HttpDelete]
        public async Task<IActionResult> RemoveDriverFromQueue()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");

            await driverManager.RemoveFromQueue(driver.DriverID);
            return Ok("Success");
        }
    }
}