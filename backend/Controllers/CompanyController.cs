using KoreanTaxi.Data;
using KoreanTaxi.Hubs;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Stripe;
using Twilio.Jwt.AccessToken;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = nameof(EnumUserRole.COMPANY))]
    public class CompanyController : ControllerBase
    {

        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;
        private readonly LoginManager loginManager;
        private readonly TripManager tripManager;
        private readonly CustomerManager customerManager;
        private readonly DriverManager driverManager;
        private readonly CompanyManager companyManager;
        private readonly HubManager hubManager;
        private readonly IGoogleService googleService;

        public CompanyController(TaxiDbContext ctx, IUserService userService, LoginManager loginManager, TripManager tripManager, CustomerManager customerManager, DriverManager driverManager, CompanyManager companyManager, HubManager hubManager, IGoogleService googleService)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.loginManager = loginManager;
            this.tripManager = tripManager;
            this.customerManager = customerManager;
            this.driverManager = driverManager;
            this.companyManager = companyManager;
            this.hubManager = hubManager;
            this.googleService = googleService;
        }

        [HttpPost("NewTrip")]
        public async Task<IActionResult> NewTrip(CompanyTripInquiry tripInquiry)
        {
            // get login id
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            // check if it is company
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            // get pickup location incase if it was saved
            var savedPickupLocation = await tripManager.GetGoogleLocation(tripInquiry.PickupAddress, tripInquiry.PickupName, tripInquiry.PickupLatitude, tripInquiry.PickupLongitude, tripInquiry.LocationType);

            // create new trip with only pick up location
            var newTrip = new Trip(null, company.CompanyID, savedPickupLocation.GoogleLocationID, null);

            // go straight to matching..
            newTrip.TripStatus = EnumTripStatus.MATCHING;
            newTrip.Notes = tripInquiry.Notes;
            newTrip.CustomerPhoneNumber = !String.IsNullOrEmpty(tripInquiry.CustomerPhoneNumber) ? tripInquiry.CustomerPhoneNumber : string.Empty;
            newTrip.CalledTaxiSize = tripInquiry.EnumTaxiSize;
            newTrip.TripType = tripInquiry.EnumTripType;
            //newTrip.TripType = EnumTripType.CASH;

            await ctx.Trips.AddAsync(newTrip);
            // save trip to get the id
            await ctx.SaveChangesAsync();

            //// add to customerQueue
            var customerQueue = new CustomerQueue(null, company.CompanyID, newTrip.TripID);
            await ctx.CustomerQueues.AddAsync(customerQueue);
            await ctx.SaveChangesAsync();

            // Sending regular trip to be added to another dispatcher's screen
            // var tripReturnForCompany = await tripManager.GetCurrentTripCompany(newTrip);
            // await hubManager.SendToClient($"{Constants.COMPANY}{company.CompanyID}", Constants.COMPANYTRIP, EnumTripStatus.MATCHING, tripReturnForCompany);
            
            if (newTrip.TripType == EnumTripType.ALCOHOL1)
            {
                var alcoholTrip = tripManager.CloneTripForAlcohol(newTrip);
                await ctx.Trips.AddAsync(alcoholTrip);
                await ctx.SaveChangesAsync();
                var alcoholCustomerQueue = new CustomerQueue(null, company.CompanyID, alcoholTrip.TripID);
                await ctx.CustomerQueues.AddAsync(alcoholCustomerQueue);

                newTrip.AlcoholTripID = alcoholTrip.TripID;
                await ctx.SaveChangesAsync();

                // Sending alcoholTrip to be added to the website
                var alcoholTripReturnForCompany = await tripManager.GetCurrentTripCompany(alcoholTrip);
                await hubManager.SendToClient($"{Constants.COMPANY}{company.CompanyID}", Constants.COMPANYTRIP, EnumTripStatus.MATCHING, alcoholTripReturnForCompany);

            }

            var retObj = new
            {
                newTrip.TripID,
            };

            return Ok(retObj);
        }

        [HttpPost("UpdateTripNote"), Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        public async Task<IActionResult> UpdateTripNote(long tripID, string notes)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            // check if it is company
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var trip = await tripManager.GetTripByID(tripID);
            if (trip == null) return NotFound("Trip Not Found");

            trip.Notes = notes;
            await ctx.SaveChangesAsync();

            await hubManager.SendToClient($"{Constants.DRIVER}{trip.DriverID}", Constants.NOTEUPDATE, tripID, notes);

            return Ok("Success");
        }


        [HttpPost("UpdateTripPrice"), Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        public async Task<IActionResult> UpdateTripPrice(long tripID, decimal price)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            // check if it is company
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var trip = await tripManager.GetTripByID(tripID);
            if (trip == null) return NotFound("Trip Not Found");

            trip.CompanyTripAmount = price;
            await ctx.SaveChangesAsync();

            await hubManager.SendToClient($"{Constants.DRIVER}{trip.DriverID}", Constants.PRICEUPDATE, tripID, price);

            return Ok("Success");
        }

        [HttpPost("DeleteAllArrival")]
        public async Task<IActionResult> DeleteAllArrival()
        {
            // get login id
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            // check if it is company
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");


            var cqs = ctx.CustomerQueues.Include(cq => cq.Trip).Where(cq => cq.CompanyID == company.CompanyID && cq.Trip.TripStatus == EnumTripStatus.COMPLETED);

            ctx.CustomerQueues.RemoveRange(cqs);
            await ctx.SaveChangesAsync();

            return Ok("Success");
        }

        [HttpPost("CancelTrip")]
        public async Task<IActionResult> CancelTrip(long tripID)
        {
            // get login id
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            // check if it is company
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var trip = await tripManager.GetTripByID(tripID);
            if (trip == null) return NotFound("Trip Not Found");

            if (trip.TripStatus == EnumTripStatus.COMPLETED)
            {
                await tripManager.RemoveCustomerQueueByTripID(tripID);
                await ctx.SaveChangesAsync();
                return Ok("Success");
            }

            if (trip.DriverID != null)
            {
                var driverQueue = await driverManager.GetDriverQueueByDriverID(trip.DriverID.Value);
                if (driverQueue == null) return NotFound("Driver Queue Not Found");

                driverQueue.QueueStatus = EnumQueueStatus.COMPANYCANCELED;
                driverQueue.TripID = null;
                driverQueue.CustomerQueueID = null;
                await hubManager.SendToClient($"{Constants.DRIVER}{trip.DriverID}", Constants.COMPANYCANCEL, EnumTripStatus.COMPANYCANCELED, trip.TripID);
            }

            trip.TripStatus = EnumTripStatus.COMPANYCANCELED;
            await tripManager.RemoveCustomerQueueByTripID(tripID);

         
            await ctx.SaveChangesAsync();

            await hubManager.SendToClient($"{Constants.COMPANY}{company.CompanyID}", Constants.COMPANYCANCEL, EnumTripStatus.COMPANYCANCELED, tripID);


            return Ok("Success");
        }

        [HttpGet("Trips")]
        public async Task<IActionResult> GetTrips()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var trips = await tripManager.GetCurrentTripsCompany(company.CompanyID);

            return Ok(trips);
        }

        [HttpGet("GetCompanyDriverLocations")]
        public async Task<IActionResult> GetCompanyDriverLocations()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var drivers = await ctx.Drivers.Include(x => x.DriverQueue).Where(x => x.CompanyID == company.CompanyID && x.IsArchived == null).ToListAsync();

            List<DriverLocationReturn> lod = new List<DriverLocationReturn>();
            foreach (var driver in drivers)
            {
                var dl = new DriverLocationReturn()
                {
                    DriverID = driver.DriverID,
                    Name = driver.DriverNumber.ToString()
                };
                var dq = driver.DriverQueue;
                if (dq != null)
                {
                    dl.IsWorking = true;
                    dl.Latitude = dq.Latitude;
                    dl.Longitude = dq.Longitude;
                }
                lod.Add(dl);
            }


            return Ok(lod.OrderByDescending(x => x.IsWorking));
        }




        [HttpGet("GetCompanyTrips")]
        public async Task<IActionResult> GetCompanyTrips()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).Include(x => x.CompanyQueues).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var trips = company.CompanyQueues.Select(x => x.Trip).ToList();

            //return trips format it
            return Ok(trips);
        }

        [HttpGet("GetCompanyCustomerPhoneNumber")]
        public async Task<IActionResult> GetCompanyCustomerPhoneNumber(string name = "all")
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            name = name.Replace(" ", "").ToLower();

            var data = companyManager.GetCompanyCustomerPhoneNumbers(company.CompanyID).Include(x => x.GoogleLocation).ThenInclude(x => x.CompanyGoogleLocation)
                .Where(x => name == "all" || x.CustomerName.Replace(" ", "").ToLower().Contains(name))
                .Select(x => new CompanyCustomerPhoneNumberRequest
                {
                    CompanyCustomerPhoneNumberID = x.CompanyCustomerPhoneNumberID,
                    CustomerName = x.CustomerName,
                    PhoneNumber = x.PhoneNumber,
                    LocationName = x.GoogleLocation == null ? "" : x.GoogleLocation.Name,
                    LocationAddress = x.GoogleLocation == null ? "" : x.GoogleLocation.Address,
                    LocationPreferredName = x.GoogleLocation == null ? "" : x.GoogleLocation.CompanyGoogleLocation == null ? "" : x.GoogleLocation.CompanyGoogleLocation.Name,
                });

            var res = await data.ToListAsync();
            return Ok(res);
        }

        [HttpPost("AddCompanyCustomerPhoneNumber")]
        public async Task<IActionResult> AddCompanyCustomerPhoneNumber(CompanyCustomerPhoneNumberRequest req)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            GoogleLocation? location = null;

            if (req.LocationName != "")
            {
                location = await tripManager.GetGoogleLocation(req.LocationAddress, req.LocationName, req.LocationLatitude, req.LocationLongitude, req.LocationType);
            }

            await companyManager.InsertIntoCompanyCustomerPhoneNumber(company.CompanyID, location?.GoogleLocationID, req.PhoneNumber, req.CustomerName);

            return Ok("Success");
        }

        [HttpPost("EditCompanyCustomerPhoneNumber")]
        public async Task<IActionResult> EditCompanyCustomerPhoneNumber(CompanyCustomerPhoneNumberRequest req)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            GoogleLocation? location = null;

            if (req.LocationName != "")
            {
                location = await tripManager.GetGoogleLocation(req.LocationAddress, req.LocationName, req.LocationLatitude, req.LocationLongitude, req.LocationType);
            }

            await companyManager.UpdateCompanyCustomerPhoneNumber(req.CompanyCustomerPhoneNumberID, company.CompanyID, location?.GoogleLocationID, req.PhoneNumber, req.CustomerName);

            return Ok("Success");
        }

        [HttpDelete("DeleteCompanyCustomerPhoneNumber")]
        public async Task<IActionResult> DeleteCompanyCustomerPhoneNumber(long companyCustomerPhoneNumberID)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var ret = await companyManager.DeleteCompanyCustomerPhoneNumber(companyCustomerPhoneNumberID, company.CompanyID);

            return ret == string.Empty ? BadRequest("Cannot find the Customer") : Ok(ret);
        }

        [HttpPost("DeleteCompanyCustomerPhoneNumbers")]
        public async Task<IActionResult> DeleteCompanyCustomerPhoneNumbers(List<long> customerIDs)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            foreach (var id in customerIDs)
            {
                await companyManager.DeleteCompanyCustomerPhoneNumber(id, company.CompanyID);
            }


            return Ok("Success");
        }


        [HttpPost("CreateCompany"), AllowAnonymous]
        public async Task<IActionResult> CreateCompany(CompanyCreateRequest request)
        {
            var loginUser = new LoginUser()
            {
                Username = request.UserName,
                Password = request.Password,
                Role = EnumUserRole.COMPANY,
                IsActive = true,
                CreatedDateTime = DateTime.UtcNow,
            };

            await ctx.LoginUsers.AddAsync(loginUser);

            var company = new Company()
            {
                Name = request.CompanyName,
                PhoneNumber = request.PhoneNumber,
                ContactName = request.CompanyContact,
                Address1 = request.Address1,
                Address2 = request.Address2,
                City = request.City,
                State = request.State,
                Zip = request.Zip,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
            };

            await ctx.Companies.AddAsync(company);
            await ctx.SaveChangesAsync();

            var companyUser = new CompanyUser()
            {
                Name = request.DispatchName,
                CompanyID = company.CompanyID,
                LoginUserID = loginUser.LoginUserID,
            };

            await ctx.CompanyUsers.AddAsync(companyUser);
            await ctx.SaveChangesAsync();

            foreach (var state in request.OperatingStates)
            {
                var companyState = new CompanyOperatingState()
                {
                    CompanyID = company.CompanyID,
                    FromState = state,
                    CreatedDateTime = DateTime.UtcNow,
                };

                await ctx.CompanyOperatingStates.AddAsync(companyState);
            }
            await ctx.SaveChangesAsync();

            return Ok(company);

        }

        [HttpPost("AddDispatch"), AllowAnonymous]
        public async Task<IActionResult> AddDispatch(AddDispatchRequest request)
        {
            var loginUser = new LoginUser()
            {
                Username = request.UserName,
                Password = request.Password,
                Role = EnumUserRole.COMPANY,
                IsActive = true,
                CreatedDateTime = DateTime.UtcNow,
            };

            await ctx.LoginUsers.AddAsync(loginUser);

            await ctx.SaveChangesAsync();

            var companyUser = new CompanyUser()
            {
                Name = request.DispatchName,
                CompanyID = request.CompanyID,
                LoginUserID = loginUser.LoginUserID,
            };

            await ctx.CompanyUsers.AddAsync(companyUser);
            await ctx.SaveChangesAsync();

            return Ok(loginUser);
        }

    }
}
