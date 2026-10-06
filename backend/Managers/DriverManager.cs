using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Managers
{
    public class DriverManager
    {
        private readonly TaxiDbContext ctx;
        private readonly TripManager tripManager;

        public DriverManager(TaxiDbContext ctx, TripManager tripManager)
        {
            this.ctx = ctx;
            this.tripManager = tripManager;
        }

        public async Task<Driver?> GetDriverByLoginUserID(long loginUserID)
        {
            var driver = await ctx.Drivers.Where(x => x.LoginUserID == loginUserID).FirstOrDefaultAsync();
            return driver;
        }

        public async Task<Driver?> GetDriverByID(long driverID)
        {
            var driver = await ctx.Drivers.Include(x => x.Taxi).Include(x => x.Company).Where(x => x.DriverID == driverID).FirstOrDefaultAsync();
            return driver;
        }
        public async Task<DriverQueue?> GetDriverQueueByDriverID(long driverID)
        {
            var driverQueue = await ctx.DriverQueues.Where(x => x.DriverID == driverID).FirstOrDefaultAsync();
            return driverQueue;
        }

        public async Task<Driver> RegisterDriver(CompanyDriverRequest driverRequest, long loginUserID)
        {
            var driver = new Driver();
            //var driver = new Driver(loginUserID, driverRequest.FirstName, driverRequest.LastName, driverRequest.Email);

            var taxi = new Taxi();

            ctx.Drivers.Add(driver);
            await ctx.SaveChangesAsync();
            ctx.Taxis.Add(taxi);
            await ctx.SaveChangesAsync();
            return driver;
        }

        public bool IsTLCApproved(string licensePlate)
        {
            licensePlate = licensePlate.ToLower();
            var len = licensePlate.Length;
            if (len < 5) return false;
            // if first character is t and last is c
            if (licensePlate[0] == 't' && licensePlate[len - 1] == 'c') return true;
            return false;
        }


        public async Task<DriverQueue> AddDriverToQueue(long driverID, LatLng loc)
        {
            var newDriverQueue = new DriverQueue();
            newDriverQueue.DriverID = driverID;
            newDriverQueue.QueueStatus = EnumQueueStatus.WAITING;
            newDriverQueue.Latitude = loc.Latitude;
            newDriverQueue.Longitude = loc.Longitude;
            ctx.DriverQueues.Add(newDriverQueue);
            await ctx.SaveChangesAsync();
            return newDriverQueue;
        }

        public async Task<DriverQueue> ReAddDriverToQueue(long driverID)
        {
            var prevQueue = await ctx.DriverQueues.Where(x => x.DriverID == driverID).FirstOrDefaultAsync();
            RemoveFromQueue(driverID);
            var driverQueue = await AddDriverToQueue(driverID, new LatLng(prevQueue.Latitude, prevQueue.Longitude));
            return driverQueue;
        }

        public async Task<bool> RemoveFromQueue(long driverID, bool revertCustomerQueue = true)
        {
            var driverQueues = ctx.DriverQueues.Where(x => x.DriverID == driverID);
            var customerQueueID = driverQueues.FirstOrDefault()?.CustomerQueueID;
            var customerQueue = ctx.CustomerQueues.Where(x => x.CustomerQueueID == customerQueueID).FirstOrDefault();
            if (customerQueue != null && revertCustomerQueue)
            {
                customerQueue.QueueStatus = EnumQueueStatus.WAITING;
            }
            var driverQueueRejectedCustomerQueues = ctx.DriverQueueRejectedCustomerQueues.Include(x => x.DriverQueue).Where(x => x.DriverQueue.DriverID == driverID);
            ctx.DriverQueueRejectedCustomerQueues.RemoveRange(driverQueueRejectedCustomerQueues);
            ctx.DriverQueues.RemoveRange(driverQueues);
            await ctx.SaveChangesAsync();
            return true;
        }

        public async Task<DriverReturn> DriverReturn(long driverID)
        {

            var driver = await ctx.Drivers.Include(x => x.Taxi).Include(x => x.Company).Where(x => x.DriverID == driverID).FirstOrDefaultAsync();

            var ret = new DriverReturn(driver);
            var locs = await ctx.CompanyFrequentLocations.Include(x => x.GoogleLocation).ThenInclude(x => x.CompanyGoogleLocation).Where(x => x.CompanyID == driver.CompanyID).ToListAsync();
            if (locs.Any())
            {
                foreach (var loc in locs)
                {
                    ret.FrequentLocations.Add(new UserLocation(new GoogleLocation 
                    { 
                        PreferredName = loc.GoogleLocation.CompanyGoogleLocation?.Name ?? string.Empty,
                        Name = loc.GoogleLocation.Name, 
                        Address = loc.GoogleLocation.Address,
                        Latitude = loc.GoogleLocation.Latitude,
                        Longitude = loc.GoogleLocation.Longitude,
                        LocationType= loc.GoogleLocation.LocationType,
                        GoogleLocationID= loc.GoogleLocation.GoogleLocationID,
                    }));
                }
            }
            

            var trips = await tripManager.GetDriverRecentTrips(driverID, 0);
            decimal earned = (decimal)0.00;
            foreach (var trip in trips)
            {
                earned += trip.Payment?.FullAmount ?? (decimal)0.00;
            }
            ret.EarnedToday = earned;

            return ret;
        }


    }
}
