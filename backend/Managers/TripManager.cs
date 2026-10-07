using KoreanTaxi.Data;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Models;
using KoreanTaxi.Services;
using Microsoft.EntityFrameworkCore;
using KoreanTaxi.Models.Enums;
using Stripe;
using USAddress;
using BingMapsRESTToolkit;
using KoreanTaxi.Helper;
using System.Collections.Generic;
//using KoreanTaxi.Migrations;
using System.Net.NetworkInformation;
using System.Security.Cryptography.X509Certificates;
using Twilio.Types;
using System.ComponentModel.Design;
using KoreanTaxi.Controllers;

namespace KoreanTaxi.Managers
{
    public class TripManager
    {
        private readonly TaxiDbContext ctx;
        private readonly HubManager hubManager;
        private readonly IGoogleService googleService;

        public TripManager(TaxiDbContext ctx, HubManager hubManager, IGoogleService googleService)
        {
            this.ctx = ctx;
            this.hubManager = hubManager;
            this.googleService = googleService;
        }

        public async Task<GoogleLocation> GetGoogleLocation(string address, string name, double latitude, double longitude, EnumLocationType locType = EnumLocationType.OTHER)
        {
            var savedLocation = await ctx.GoogleLocations.Include(x => x.CompanyGoogleLocation).Where(x => x.Address == address && x.Name == name).FirstOrDefaultAsync();

            if (savedLocation == null)
            {
                savedLocation = new GoogleLocation();
                savedLocation.Address = address;
                savedLocation.Name = name;
                savedLocation.Latitude = latitude;
                savedLocation.Longitude = longitude;
                savedLocation.State = GetState(name, address);
                savedLocation.LocationType = locType;
                await ctx.GoogleLocations.AddAsync(savedLocation);
                await ctx.SaveChangesAsync();
            }
            return savedLocation;
        }

        public async Task<Trip> GetTripByCustomerQueueID(long customerQueueID)
        {
            var trip = await ctx.CustomerQueues.Include(cq => cq.Trip).Where(cq => cq.CustomerQueueID == customerQueueID).Select(cq => cq.Trip).FirstOrDefaultAsync();
            return trip;
        }

        public async Task<GoogleLocation> GetGoogleLocation(long? googleLocationID)
        {
            var savedLocation = await ctx.GoogleLocations.Include(x => x.CompanyGoogleLocation).Where(x => x.GoogleLocationID == googleLocationID).FirstOrDefaultAsync();
            return savedLocation;
        }

        public async Task<Trip?> GetTripByID(long tripID)
        {
            try
            {
                var trip = await ctx.Trips.Include(t => t.CustomerQueue).Where(x => x.TripID == tripID).FirstOrDefaultAsync();
                return trip;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
            return null;
        }

        //Same trip for app taxi only
        public async Task<Trip?> GetSameTrip(Trip trip)
        {
            var curMonth = DateTime.UtcNow.Month;
            var curYear = DateTime.UtcNow.Year;
            var sameTrip = await ctx.Trips.Where(x => x.CreatedDateTime.Month == curMonth
                                       && x.CreatedDateTime.Year == curYear
                                       && x.PickupLocationID == trip.PickupLocationID
                                       && x.DropoffLocationID == trip.DropoffLocationID
                                       && x.CompanyID == null).FirstOrDefaultAsync();
            return sameTrip;
        }

        public Trip CloneTrip(Trip trip)
        {
            return new Trip()
            {
                CompanyID = trip.CompanyID,
                PickupLocationID = trip.PickupLocationID,
                TripStatus = trip.TripStatus,
                Notes = trip.Notes,
                CustomerPhoneNumber = trip.CustomerPhoneNumber,
                CalledTaxiSize = trip.CalledTaxiSize,
                TripType = trip.TripType,
            };
        }

        public Trip CloneTripForAlcohol(Trip trip)
        {
            var newTrip = CloneTrip(trip);
            newTrip.AlcoholTripID = trip.TripID;
            newTrip.TripType = EnumTripType.ALCOHOL2;
            return newTrip;
        }

        public async Task MatchAlcoholTrip(Trip trip)
        {
            if (trip.TripType == EnumTripType.ALCOHOL1 || trip.TripType == EnumTripType.ALCOHOL2)
            {
                var otherAlcoholTrip = await ctx.Trips.Include(x => x.Driver).Where(x => x.TripID == trip.AlcoholTripID).FirstOrDefaultAsync();
                if (otherAlcoholTrip != null && otherAlcoholTrip.DriverID != null)
                {
                    var tripDriver = await ctx.Drivers.Where(x => x.DriverID == trip.DriverID).FirstOrDefaultAsync();
                    otherAlcoholTrip.AlcoholPhoneNumber = tripDriver.PhoneNumber;
                    trip.AlcoholPhoneNumber = otherAlcoholTrip.Driver.PhoneNumber;

                    await ctx.SaveChangesAsync();

                    await hubManager.SendToClient($"{Constants.DRIVER}{otherAlcoholTrip.DriverID}", Constants.ALCOHOLDRIVERMATCH, otherAlcoholTrip.TripID, otherAlcoholTrip.AlcoholPhoneNumber);
                    await hubManager.SendToClient($"{Constants.DRIVER}{trip.DriverID}", Constants.ALCOHOLDRIVERMATCH, trip.TripID, trip.AlcoholPhoneNumber);
                }

            }
        }



        //Rename this
        public async Task<Trip?> GetFindFareTrip(long customerID, long tripID)
        {
            var trip = await ctx.Trips.Include(x => x.PickupLocation).Where(x => x.TripID == tripID
                                               && x.CustomerID == customerID
                                               && (x.TripStatus == EnumTripStatus.CUSTOMERSEARCHING || x.TripStatus == EnumTripStatus.CUSTOMERCANCELED)).FirstOrDefaultAsync();
            return trip;
        }

        public async Task<Trip?> GetCurrentTripCustomer(long customerID)
        {

            var customerQueue = await ctx.CustomerQueues.Where(x => x.CustomerID == customerID).FirstOrDefaultAsync();
            if (customerQueue == null) return null;
            var trip = await ctx.Trips.Include(x => x.Payment).Where(x => x.TripID == customerQueue.TripID).FirstOrDefaultAsync();
            return trip;
        }

        public async Task<List<TripReturnForCompany>> GetCurrentTripsCompany(long companyID)
        {
            var trips = await ctx.CustomerQueues
                .AsNoTracking()
                .Include(x => x.Trip)
                .Where(x => x.CompanyID == companyID)
                .Select(cq => new TripReturnForCompany
                {
                    TripID = cq.Trip.TripID,
                    TripStatus = cq.Trip.TripStatus,
                    CreatedDateTime = cq.Trip.CreatedDateTime,
                    PhoneNumber = cq.Trip.CustomerPhoneNumber,
                    Notes = cq.Trip.Notes,
                    CompanyTripPrice = cq.Trip.CompanyTripAmount,
                    StartLocationId = cq.Trip.PickupLocationID,
                    EndLocationId = cq.Trip.DropoffLocationID,
                    DriverId = cq.Trip.DriverID,
                })
                .OrderBy(x => x.CreatedDateTime)
                .ToListAsync();

            var startLocationIds = trips.Select(trip => trip.StartLocationId).Where(id => id != null).Distinct().ToList();
            var endLocationIds = trips.Select(trip => trip.EndLocationId).Where(id => id != null).Distinct().ToList();
            var driverIds = trips.Select(trip => trip.DriverId).Where(id => id != null).Distinct().ToList();

            var startLocations = await ctx.GoogleLocations
                .Include(x => x.CompanyGoogleLocation)
                .AsNoTracking()
                .Where(gl => startLocationIds.Contains(gl.GoogleLocationID))
                .ToListAsync();

            var endLocations = await ctx.GoogleLocations
                .Include(x => x.CompanyGoogleLocation)
                .AsNoTracking()
                .Where(gl => endLocationIds.Contains(gl.GoogleLocationID))
                .ToListAsync();

            var drivers = await ctx.Drivers
                .AsNoTracking()
                .Include(d => d.Taxi)
                .Where(d => driverIds.Contains(d.DriverID))
                .ToListAsync();

            foreach (var trip in trips)
            {
                if (trip.StartLocationId != null)
                {
                    var startLocation = startLocations.FirstOrDefault(gl => gl.GoogleLocationID == trip.StartLocationId);
                    if (startLocation != null)
                    {
                        if (startLocation.CompanyGoogleLocation != null)
                        {
                            trip.StartPreferredName = startLocation.CompanyGoogleLocation.Name;
                        }
                        trip.StartAddress = startLocation.Address;
                        trip.StartName = startLocation.Name;
                        trip.StartLatitude = startLocation.Latitude;
                        trip.StartLongitude = startLocation.Longitude;
                        trip.StartLocationType = startLocation.LocationType;
                    }
                }
                if (trip.EndLocationId != null)
                {
                    var endLocation = endLocations.FirstOrDefault(gl => gl.GoogleLocationID == trip.EndLocationId);
                    if (endLocation != null)
                    {
                        if (endLocation.CompanyGoogleLocation != null)
                        {
                            trip.EndPreferredName = endLocation.CompanyGoogleLocation.Name;
                        }
                        trip.EndAddress = endLocation.Address;
                        trip.EndName = endLocation.Name;
                        trip.EndLatitude = endLocation.Latitude;
                        trip.EndLongitude = endLocation.Longitude;
                        trip.EndLocationType = endLocation.LocationType;
                    }
                }
                if (trip.DriverId != null)
                {
                    var driver = drivers.FirstOrDefault(d => d.DriverID == trip.DriverId);
                    if (driver != null)
                    {
                        trip.DriverNumber = driver.DriverNumber;
                        trip.DriverPhoneNumber = driver.PhoneNumber;
                        trip.Color = driver.Taxi?.Color;
                        trip.Make = driver.Taxi?.Make;
                        trip.Model = driver.Taxi?.Model;
                        trip.LicensePlate = driver.Taxi?.LicensePlate;
                    }
                }
            }

            return trips;
        }
        public async Task<TripReturnForCompany> GetCurrentTripCompany(Trip trip)
        {

            var tripReturn = await ctx.CustomerQueues
              .AsNoTracking()
              .Include(x => x.Trip)
              .Where(x => x.TripID == trip.TripID)
              .Select(cq => new TripReturnForCompany
              {
                  TripID = cq.Trip.TripID,
                  TripStatus = cq.Trip.TripStatus,
                  CreatedDateTime = cq.Trip.CreatedDateTime,
                  PhoneNumber = cq.Trip.CustomerPhoneNumber,
                  Notes = cq.Trip.Notes,
                  CompanyTripPrice = cq.Trip.CompanyTripAmount,
                  StartLocationId = cq.Trip.PickupLocationID,
                  EndLocationId = cq.Trip.DropoffLocationID,
                  DriverId = cq.Trip.DriverID,
              }).FirstOrDefaultAsync();


            if (tripReturn.StartLocationId != null)
            {
                var startLocation = await ctx.GoogleLocations
      .Include(x => x.CompanyGoogleLocation)
      .AsNoTracking()
      .Where(gl => tripReturn.StartLocationId == gl.GoogleLocationID)
      .FirstOrDefaultAsync();
                if (startLocation != null)
                {
                    if (startLocation.CompanyGoogleLocation != null)
                    {
                        tripReturn.StartPreferredName = startLocation.CompanyGoogleLocation.Name;
                    }
                    tripReturn.StartAddress = startLocation.Address;
                    tripReturn.StartName = startLocation.Name;
                    tripReturn.StartLatitude = startLocation.Latitude;
                    tripReturn.StartLongitude = startLocation.Longitude;
                    tripReturn.StartLocationType = startLocation.LocationType;
                }
            }
            if (tripReturn.EndLocationId != null)
            {
                var endLocation = await ctx.GoogleLocations
      .Include(x => x.CompanyGoogleLocation)
      .AsNoTracking()
      .Where(gl => tripReturn.EndLocationId.Value == gl.GoogleLocationID)
      .FirstOrDefaultAsync();

                if (endLocation != null)
                {
                    if (endLocation.CompanyGoogleLocation != null)
                    {
                        tripReturn.EndPreferredName = endLocation.CompanyGoogleLocation.Name;
                    }
                    tripReturn.EndAddress = endLocation.Address;
                    tripReturn.EndName = endLocation.Name;
                    tripReturn.EndLatitude = endLocation.Latitude;
                    tripReturn.EndLongitude = endLocation.Longitude;
                    tripReturn.EndLocationType = endLocation.LocationType;
                }
            }

            if (tripReturn.DriverId != null)
            {
                var driver = await ctx.Drivers
            .AsNoTracking()
            .Include(d => d.Taxi)
            .Where(d => tripReturn.DriverId.Value == d.DriverID)
            .FirstOrDefaultAsync();
                if (driver != null)
                {
                    tripReturn.DriverNumber = driver.DriverNumber;
                    tripReturn.DriverPhoneNumber = driver.PhoneNumber;
                    tripReturn.Color = driver.Taxi?.Color;
                    tripReturn.Make = driver.Taxi?.Make;
                    tripReturn.Model = driver.Taxi?.Model;
                    tripReturn.LicensePlate = driver.Taxi?.LicensePlate;
                }
            }
            return tripReturn;
        }

        public async Task<Trip?> GetCurrentTripDriver(long driverID)
        {

            var driverQueue = await ctx.DriverQueues.Where(x => x.DriverID == driverID).FirstOrDefaultAsync();
            if (driverQueue == null) return null;
            var trip = await ctx.Trips.Include(x => x.Payment).Where(x => x.TripID == driverQueue.TripID).FirstOrDefaultAsync();
            return trip;
        }

        public async Task<List<Trip>> GetCustomerRecentTrips(long customerID)
        {
            var trips = await ctx.Trips.Include(x => x.Driver)
                           .Include(x => x.PickupLocation)
                           .Include(x => x.DropoffLocation)
                           .Include(x => x.Payment)
                           .Where(x => x.CustomerID == customerID
                               && x.TripStatus == EnumTripStatus.COMPLETED
                               && x.Payment != null
                               && x.Payment.PaymentStatus == EnumPaymentStatus.PAID).ToListAsync();

            return trips;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="driverID"></param>
        /// <param name="filterType">
        ///     0 = Today
        ///     1 = This Week
        ///     2 = This month
        ///     3 = Last month
        ///     4 = Everything
        /// </param>
        /// <returns></returns>
        public async Task<List<Trip>> GetDriverRecentTrips(long driverID, int filterType = 4)
        {
            List<Trip> trips = new List<Trip>();
            DateTime today = DateTime.Today;
            int offset = today.DayOfWeek - DayOfWeek.Monday;
            DateTime monday = today.AddDays(-offset);
            DateTime sunday = monday.AddDays(6);
            try
            {
                trips = await ctx.Trips.Include(x => x.Customer)
                           .Include(x => x.PickupLocation)
                           .Include(x => x.DropoffLocation)
                           .Include(x => x.Payment)
                           .Where(x => x.DriverID == driverID
                               && x.TripStatus == EnumTripStatus.COMPLETED
                               && x.Payment != null
                               && x.Payment.PaymentStatus == EnumPaymentStatus.PAID
                               && ((filterType == 0 && x.CreatedDateTime.Day == today.Day && x.CreatedDateTime.Month == today.Month && x.CreatedDateTime.Year == today.Year)
                               || (filterType == 1 && monday <= x.CreatedDateTime && x.CreatedDateTime <= sunday)
                               || (filterType == 2 && x.CreatedDateTime.Month == today.Month && x.CreatedDateTime.Year == today.Year)
                               || (filterType == 3 && x.CreatedDateTime.Month == today.AddMonths(-1).Month && x.CreatedDateTime.Year == today.AddMonths(-1).Year)
                               || (filterType == 4)))
                           .OrderByDescending(x => x.CreatedDateTime)
                           .ToListAsync();
            }
            catch (Exception ex)
            {
            }

            return trips;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="driverID"></param>
        /// <param name="filterType">
        ///     0 = Today
        ///     1 = This Week
        ///     2 = This month
        ///     3 = Last month
        ///     4 = Everything
        /// </param>
        /// <returns></returns>
        public async Task<List<Trip>> GetCustomerRecentTrips(long customerID, int filterType = 4)
        {
            List<Trip> trips = new List<Trip>();
            DateTime today = DateTime.Today;
            int offset = today.DayOfWeek - DayOfWeek.Monday;
            DateTime monday = today.AddDays(-offset);
            DateTime sunday = monday.AddDays(6);
            try
            {
                trips = await ctx.Trips.Include(x => x.Customer)
                           .Include(x => x.PickupLocation)
                           .Include(x => x.DropoffLocation)
                           .Include(x => x.Payment)
                           .Where(x => x.CustomerID == customerID
                               && x.TripStatus == EnumTripStatus.COMPLETED
                               && x.Payment != null
                               && x.Payment.PaymentStatus == EnumPaymentStatus.PAID
                               && ((filterType == 0 && x.CreatedDateTime.Day == today.Day && x.CreatedDateTime.Month == today.Month && x.CreatedDateTime.Year == today.Year)
                               || (filterType == 1 && monday <= x.CreatedDateTime && x.CreatedDateTime <= sunday)
                               || (filterType == 2 && x.CreatedDateTime.Month == today.Month && x.CreatedDateTime.Year == today.Year)
                               || (filterType == 3 && x.CreatedDateTime.Month == today.AddMonths(-1).Month && x.CreatedDateTime.Year == today.AddMonths(-1).Year)
                               || (filterType == 4)))
                           .OrderByDescending(x => x.CreatedDateTime)
                           .ToListAsync();
            }
            catch (Exception ex)
            {
            }

            return trips;
        }

        public async Task<CustomerQueue?> RemoveCustomerQueue(long customerID)
        {
            var customerQueue = await ctx.CustomerQueues.Where(x => customerID == x.CustomerID).FirstOrDefaultAsync();
            if (customerQueue == null) { return null; }
            await ReleasePendingOffer(customerQueue.TripID);
            ctx.CustomerQueues.Remove(customerQueue);
            await ctx.SaveChangesAsync();

            return customerQueue;
        }


        public async Task<CustomerQueue?> RemoveCustomerQueueByTripID(long tripID)
        {
            var customerQueue = await ctx.CustomerQueues.Where(x => x.TripID == tripID).FirstOrDefaultAsync();
            if (customerQueue == null) { return null; }
            await ReleasePendingOffer(customerQueue.TripID);
            ctx.CustomerQueues.Remove(customerQueue);
            await ctx.SaveChangesAsync();

            return customerQueue;
        }

        private async Task ReleasePendingOffer(long tripID)
        {
            var pending = await ctx.DriverQueues.Where(x => x.TripID == tripID && x.QueueStatus == EnumQueueStatus.PENDING).ToListAsync();
            foreach (var driver in pending)
            {
                driver.QueueStatus = EnumQueueStatus.WAITING;
                driver.TripID = null;
                driver.CustomerQueueID = null;
            }
        }

        public bool IsAddressCity(string address, string city)
        {
            address = address.ToLower();
            address = address.Replace(" ", "");
            if (address.Contains(city.ToLower())) return true;

            return false;

        }

        public EnumState GetState(string name, string address)
        {
            var fullAddress = $"{name}, {address}";
            fullAddress = fullAddress.Contains("United States") ? fullAddress.Replace(", United States", "") : fullAddress;
            fullAddress = fullAddress.Contains(", USA") ? fullAddress.Replace(", USA", "") : fullAddress;
            EnumState state = EnumState.UNKNOWN;
            AddressParser parser = new AddressParser();
            var parseAddress = parser.ParseAddress(fullAddress);
            var states = Enum.GetValues(typeof(EnumState)).Cast<EnumState>().ToList();
            if (parseAddress != null)
            {
                foreach (var s in states)
                {
                    if (parseAddress.State == "NY")
                    {
                        if (parseAddress.City == "NEW YORK CITY") state = EnumState.NYC;
                        else state = EnumState.NY;
                        break;
                    }
                    if (s.ToString() == parseAddress.State)
                    {
                        state = s;
                        break;
                    }
                }
            }
            if (state == EnumState.UNKNOWN)
            {
                var lowerAddress = address.ToLower();
                lowerAddress = lowerAddress.Replace(" ", "");

                foreach (var s in states)
                {
                    if (lowerAddress.Contains("newyorkcity,newyork"))
                    {
                        state = EnumState.NYC;
                        break;
                    }
                    if (lowerAddress.Contains($",{DbHelper.GetDescription(s).ToLower()}"))
                    {
                        state = s;
                        break;
                    }
                }
            }

            if (state == EnumState.UNKNOWN)
            {
                var stateCode = System.Text.RegularExpressions.Regex
                    .Matches(fullAddress.ToUpperInvariant(), @"\b[A-Z]{2}\b")
                    .Select(match => match.Value)
                    .FirstOrDefault(code => Enum.TryParse<EnumState>(code, out var parsed) && parsed != EnumState.UNKNOWN);

                if (stateCode != null && Enum.TryParse<EnumState>(stateCode, out var parsedState))
                {
                    state = parsedState;
                }
            }
            return state;
        }


        public async Task<TripReturnForCustomer> TripReturnForCustomer(Trip trip)
        {
            var ret = new TripReturnForCustomer(trip);

            var start = await GetGoogleLocation(trip.PickupLocationID);
            if (start != null)
            {
                if (start.CompanyGoogleLocation != null)
                {
                    ret.StartPreferredName = start.CompanyGoogleLocation.Name;
                }
                ret.StartName = start.Name;
                ret.StartAddress = start.Address;
                ret.StartLatitude = start.Latitude;
                ret.StartLongitude = start.Longitude;
                ret.StartLocationType = start.LocationType;
            }

            var end = await GetGoogleLocation(trip.DropoffLocationID);
            if (end != null)
            {
                if (end.CompanyGoogleLocation != null)
                {
                    ret.StartPreferredName = end.CompanyGoogleLocation.Name;
                }
                ret.EndName = end.Name;
                ret.EndAddress = end.Address;
                ret.EndLatitude = end.Latitude;
                ret.EndLongitude = end.Longitude;
                ret.EndLocationType = end.LocationType;
            }

            var payment = ctx.Payments.Where(x => x.TripID == trip.TripID).FirstOrDefault();
            if (payment != null)
            {
                ret.CustomerCardID = payment.CustomerCardID;
                ret.EnumPaymentType = payment.PaymentType;
                ret.PointUsed = payment.PointAmount;
            }

            return ret;
        }

        public async Task<TripReturnForDriver> TripReturnForDriver(Trip trip)
        {
            var ret = new TripReturnForDriver(trip);

            var start = await GetGoogleLocation(trip.PickupLocationID);
            if (start != null)
            {
                if (start.CompanyGoogleLocation != null)
                {
                    ret.StartPreferredName = start.CompanyGoogleLocation.Name;
                }
                ret.StartName = start.Name;
                ret.StartAddress = start.Address;
                ret.StartLatitude = start.Latitude;
                ret.StartLongitude = start.Longitude;
            }

            var end = await GetGoogleLocation(trip.DropoffLocationID);
            if (end != null)
            {
                if (end.CompanyGoogleLocation != null)
                {
                    ret.EndPreferredName = end.CompanyGoogleLocation.Name;
                }
                ret.EndName = end.Name;
                ret.EndAddress = end.Address;
                ret.EndLatitude = end.Latitude;
                ret.EndLongitude = end.Longitude;
            }

            var payment = await ctx.Payments.Where(x => x.TripID == trip.TripID).FirstOrDefaultAsync();
            if (payment != null)
            {
                ret.TripAmount = payment.FullAmount;
                ret.PaymentType = payment.PaymentType;
            }
            else
            {
                ret.TripAmount = trip.CompanyTripAmount;
            }

            var customer = await ctx.Customers.Where(x => x.CustomerID == trip.CustomerID).FirstOrDefaultAsync();
            if (customer != null)
            {
                ret.CustomerFirstName = customer.FirstName;
                ret.CustomerPhoneNumber = customer.PhoneNumber;
            }
            else
            {
                var company = await ctx.Companies.Where(x => x.CompanyID == trip.CompanyID).FirstOrDefaultAsync();
                ret.CustomerFirstName = company.Name;
                ret.CustomerPhoneNumber = trip.CustomerPhoneNumber;
            }

            return ret;
        }

        // public TripReturnForCompany







    }
}
