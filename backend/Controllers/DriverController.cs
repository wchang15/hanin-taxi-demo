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
using Org.BouncyCastle.Ocsp;
using Stripe;
using System.Globalization;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;

namespace KoreanTaxi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]

    public class DriverController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;
        private readonly TripManager tripManager;
        private readonly DriverManager driverManager;
        private readonly CompanyManager companyManager;
        private readonly LoginManager loginManager;
        public DriverController(TaxiDbContext ctx, IUserService userService, TripManager tripManager, DriverManager driverManager, CompanyManager companyManager, LoginManager loginManager)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.tripManager = tripManager;
            this.driverManager = driverManager;
            this.companyManager = companyManager;
            this.loginManager = loginManager;
        }

        [Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        [HttpGet("GetCompanyDrivers")]
        public async Task<IActionResult> GetCompanyDrivers()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");


            var drivers = await ctx.Drivers.Include(d => d.Taxi).Include(d => d.LoginUser).Where(d => d.CompanyID == company.CompanyID && d.IsArchived == null).Select(d => new DriverParams
            {
                Id = d.DriverID,
                DriverNumber = d.DriverNumber,
                Account= d.LoginUser.Username,
                FirstName = d.FirstName,
                LastName = d.LastName,
                Email = d.Email,
                PhoneNumber = d.PhoneNumber,
                Language = d.Language,
                Color = d.Taxi.Color,
                Make = d.Taxi.Make,
                Size = d.Taxi.Size,
                Model = d.Taxi.Model,
                LicensePlate = d.Taxi.LicensePlate,
                TLCApproved = d.TLCApproved,

            }).ToListAsync();
            return Ok(drivers);
        }

        [Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        [HttpPost("EditDriver")]
        public async Task<IActionResult> EditDriver(DriverParams edit)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");


            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync(); ;
            if (company == null) return NotFound("The Company information not found.");

            var driver = ctx.Drivers.Include(d => d.Taxi).Where(d => d.DriverID == (long)edit.Id).FirstOrDefault();

            var isDupDriverNumber = ctx.Drivers.Include(d => d.Taxi).Where(d => d.DriverNumber == edit.DriverNumber && d.CompanyID == company.CompanyID).Count();
            if (isDupDriverNumber > 1) return BadRequest("Driver Number " + edit.DriverNumber + " already exist");

            if (driver != null)
            {
                driver.FirstName = edit.FirstName;
                driver.LastName= edit.LastName;
                driver.Email = edit.Email;
                driver.PhoneNumber = edit.PhoneNumber;
                driver.DriverNumber = edit.DriverNumber;
                driver.Language = edit.Language;
                driver.Taxi.Color = edit.Color;
                driver.Taxi.Model = edit.Model;
                driver.Taxi.Make = edit.Make;
                driver.Taxi.Size = edit.Size;
                driver.Taxi.LicensePlate = edit.LicensePlate;
                driver.Taxi.DriverID = (long)edit.Id;
                driver.TLCApproved = driverManager.IsTLCApproved(edit.LicensePlate);
            }
            await ctx.SaveChangesAsync();
            return Ok(driver);
        }

        [Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        [HttpPost("ArchiveDriver")]
        public async Task<IActionResult> ArchiveDriver(long id)
        {
            var driver = ctx.Drivers.Where(d => d.DriverID == id).FirstOrDefault();
            if (driver != null)
            {
                driver.IsArchived = DateTime.UtcNow;
                await ctx.SaveChangesAsync();
            }
            return Ok(driver.FirstName);
        }

        [Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        [HttpPost("ArchiveDrivers")]
        public async Task<IActionResult> ArchiveDrivers(List<long> driverIds)
        {
            foreach (var driverId in driverIds)
            {
                var driver = ctx.Drivers.Where(d => d.DriverID == driverId).FirstOrDefault();
                if (driver != null)
                {
                    driver.IsArchived = DateTime.UtcNow;
                    await ctx.SaveChangesAsync();
                }
            }
            return Ok();
        }


        [Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        [HttpPost("CreateDriver")]
        public async Task<IActionResult> CreateDriver(DriverParams create)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var isDupUserName = ctx.LoginUsers.Where(x => x.Username == create.Account).Count();
            if (isDupUserName > 0) return BadRequest("Login Name Exist");

            var isDupDriver = ctx.Drivers.Where(d => d.DriverNumber == create.DriverNumber && d.CompanyID == company.CompanyID).Count();
            if (isDupDriver > 0) return BadRequest("Driver Number " + create.DriverNumber + " already exist");

            var terms = new List<bool>();

            var newRegisterRequest = new RegisterRequest()
            {
                Username = create.Account,
                Password = create.Passwords,
                FirstName = create.FirstName,
                LastName = create.LastName,
                PhoneNumber = create.PhoneNumber,
                Email = create.Email,
                Language= create.Language,
                Terms = terms,
                Role = EnumUserRole.DRIVER,
            };

            var user = await loginManager.RegisterLoginUser(newRegisterRequest);
            if (user == null) return BadRequest("User not created");

            // Create New Driver 1
            var newDriver = new Driver()
            {
                FirstName = create.FirstName,
                LastName = create.LastName,
                Email = create.Email,
                PhoneNumber = create.PhoneNumber,
                Language = create.Language,
                CompanyID = company.CompanyID,
                LoginUserID = user.LoginUserID,
                DriverNumber = create.DriverNumber,
                TLCApproved = driverManager.IsTLCApproved(create.LicensePlate),
            };

            await ctx.Drivers.AddAsync(newDriver);
            await ctx.SaveChangesAsync();

            // Create New Taxi everytime
            var newTaxi = new Taxi();
            newTaxi.Color = create.Color;
            newTaxi.Model = create.Model;
            newTaxi.Make = create.Make;
            newTaxi.Size = create.Size;
            newTaxi.LicensePlate = create.LicensePlate;
            newTaxi.DriverID = newDriver.DriverID;

            await ctx.Taxis.AddAsync(newTaxi);
            await ctx.SaveChangesAsync();
            return Ok(newDriver.FirstName);
        }

        [HttpPost("UpdateDefaultMap")]
        [Authorize(Roles = nameof(EnumUserRole.DRIVER))]
        public async Task<IActionResult> UpdateDefaultMap(string mapName)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");

            driver.Map= mapName;
            ctx.SaveChanges();

            return Ok("Success");
        }

        /* Company will do this
        [HttpPut("UpdateDriver")]
        public async Task<IActionResult> UpdateDriver(Driver driver)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var existingDriver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (existingDriver == null) return NotFound("The Driver information not found.");

            DbHelper.Update(existingDriver, driver);
            existingDriver.LoginUserID = (long)userID;
            await ctx.SaveChangesAsync();
            return Ok(existingDriver);
        }

        [HttpPost("AddTaxi")]
        public async Task<IActionResult> AddTaxi(Taxi taxi)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var currentTaxi = await ctx.Taxis.Where(x => x.DriverID == driver.DriverID).FirstOrDefaultAsync();
            if (currentTaxi != null) return NotFound("Taxi Already Exist.");

            var newTaxi = new Taxi();
            DbHelper.Update(newTaxi, taxi);
            newTaxi.DriverID = driver.DriverID;
            await ctx.Taxis.AddAsync(newTaxi);
            await ctx.SaveChangesAsync();

            return Ok("Success");
        }

        [HttpPut("EditTaxi")]
        public async Task<IActionResult> EditTaxi(Taxi taxi)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var currentTaxi = await ctx.Taxis.Where(x => x.DriverID == driver.DriverID && x.TaxiID == taxi.TaxiID).FirstOrDefaultAsync();
            if (currentTaxi == null) return NotFound("Taxi Not Found.");

            DbHelper.Update(currentTaxi, taxi);
            await ctx.SaveChangesAsync();
            return Ok("Success");
        }

        [HttpDelete("DeleteTaxi")]
        public async Task<IActionResult> DeleteTaxi()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var currentTaxi = await ctx.Taxis.Where(x => x.DriverID == driver.DriverID).FirstOrDefaultAsync();
            if (currentTaxi == null) return NotFound("Taxi Not Found.");

            ctx.Taxis.Remove(currentTaxi);
            await ctx.SaveChangesAsync();
            return Ok("Success");
        }
        */
        /// <summary>
        /// 
        /// </summary>
        /// <param name="filterType">
        ///     0 = Today
        ///     1 = This Week
        ///     2 = This month
        ///     3 = Last month
        ///     4 = Everything
        /// </param>
        /// <returns></returns>
        /// 
        [Authorize(Roles = nameof(EnumUserRole.DRIVER))]
        [HttpGet("GetMyCompletedTrips")]
        public async Task<IActionResult> GetDriverCompletedTrips(int filterType)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");

            var trips = await tripManager.GetDriverRecentTrips(driver.DriverID, filterType);
            decimal totalAmount = 0;

            var obj = new List<object>();
            foreach (var trip in trips)
            {
                var payment = trip.Payment;
                if (payment == null) return BadRequest("Payment not found");
                var timezoneTime = DbHelper.TimeInTimeZone(payment.CreatedDateTime, driver.Company.TimeZone);
                obj.Add(new
                {
                    amount = (payment.CardAmount + payment.PointAmount).ToString("C", Constants.USCULTURE),
                    tip = payment.TipAmount.ToString("C", Constants.USCULTURE),
                    tax = (trip.CalledTaxiSize == EnumTaxiSize.SMALL ? trip.SmallStateFeeAmount : trip.LargeStateFeeAmount).ToString("C", Constants.USCULTURE),
                    totalAmount = payment.FullAmount.ToString("C", Constants.USCULTURE),
                    date = timezoneTime.ToShortDateString(),
                    time = timezoneTime.ToString("h:mm tt"),
                    paymentType = payment.PaymentType.ToString(),
                    pickUpLocation = trip.PickupLocation.Name,
                    dropUpLocation = trip.DropoffLocation.Name,
                    mileage = trip.Mileage.ToString("0.##"),
                }); 
                totalAmount += payment.FullAmount;
            }

            var retObj = new
            {
                tripHistories = obj,
                totalAmount = totalAmount.ToString("C", Constants.USCULTURE),
            };

            return Ok(retObj);
        }

    }
}
