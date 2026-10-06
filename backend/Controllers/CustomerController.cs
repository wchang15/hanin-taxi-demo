using KoreanTaxi.Data;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using KoreanTaxi.Services;
using KoreanTaxi.Managers;
using KoreanTaxi.Helper;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
    public class CustomerController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;
        private readonly IStripeService stripeService;
        private readonly TripManager tripManager;
        private readonly CustomerManager customerManager;
        private readonly LoginManager loginManager;

        public CustomerController(TaxiDbContext ctx, IUserService userService, IStripeService stripeService, TripManager tripManager, CustomerManager customerManager, LoginManager loginManager)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.stripeService = stripeService;
            this.tripManager = tripManager;
            this.customerManager = customerManager;
            this.loginManager = loginManager;
        }


        [HttpPost("GetUsername"), AllowAnonymous]
        public async Task<IActionResult> FindUsername(PhoneNumberRequest request)
        {
            var username = await loginManager.FindCustomerUsername(request.OTP, request.PhoneNumber);
            return Ok(username);
        }


        [HttpPost("ResetPassword"), AllowAnonymous]
        public async Task<IActionResult> ResetPassword(string password, long customerID)
        {
            var customer = await customerManager.GetCustomer(customerID).Include(x => x.LoginUser).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer Not Found");
            await loginManager.UpdatePassword(password, customer.LoginUser);
            customerManager.ResetAuthNumber(customer);
            return Ok("Success");
        }

        [HttpPost("VerifyOTP"), AllowAnonymous]
        public async Task<IActionResult> VerifyOTP(PhoneNumberRequest request)
        {
            var customer = await customerManager.GetCustomerDynamicWhere(x => x.AuthNumber == request.OTP, x=> x.PhoneNumber == request.PhoneNumber).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer Not Found");
            customerManager.ResetAuthNumber(customer);

            return Ok(customer.CustomerID);
        }

        #region Phone

        //Getting phone verification code
        [HttpPost("GetOTP"), AllowAnonymous]
        public async Task<IActionResult> GetOTP(PhoneNumberRequest request, string? username)
        {
            var customer = await customerManager.GetCustomerDynamicWhere(x => x.PhoneNumber == request.PhoneNumber, x=> username == null || x.LoginUser.Username == username, x => x.IsVerified).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer Not Found");

            var authSuccess = await customerManager.SendAuthNumber(customer);

            return authSuccess ? Ok("Success") : BadRequest("Phone Number does not exist");
        }

        //Getting phone verification code
        [HttpPost("ResendOTP")]
        public async Task<IActionResult> ResendOTP()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var authSuccess = await customerManager.SendAuthNumber(customer);

            return authSuccess ? Ok("Success") : BadRequest("Phone Number does not exist");
        }

        //Used when Updating the Phone number for phone verification.
        [HttpPut("UpdatePhone")]
        public async Task<IActionResult> UpdatePhone(PhoneNumberRequest request)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var existingCustomer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (existingCustomer == null) return NotFound("The Customer information not found.");
            var cus = await customerManager.GetCustomerWithDupPhoneNumber(request.PhoneNumber, userID.Value);
            if (cus != null) return BadRequest("Phone Number already being used");

            if (!request.IsVerified)
            {
                existingCustomer.PhoneNumber = request.PhoneNumber;
                ctx.SaveChanges();
            }

            var authSuccess = await customerManager.SendAuthNumber(existingCustomer, request.PhoneNumber);
            return authSuccess ? Ok("Success") : BadRequest("Phone Number does not exist");
        }

        //Used to verify the Client's phone number.
        [HttpPut("PhoneVerify")]
        public async Task<IActionResult> VerifyPhone(PhoneNumberRequest requst)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var existingCustomer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (existingCustomer == null) return NotFound("The Customer information not found.");

            if (requst.OTP == existingCustomer.AuthNumber) // existingCustomer.AuthNumber)
            {
                if (requst.IsVerified)
                {
                    existingCustomer.PhoneNumber = requst.PhoneNumber;
                }
                existingCustomer.IsVerified = true;
                existingCustomer.AuthNumber = null;
            } else
            {
                return BadRequest("Wrong Code");
            }

            await ctx.SaveChangesAsync();
            return Ok(true);
        }

        [HttpPost("UpdateCustomer")]
        public async Task<IActionResult> UpdateCustomer(CustomerUpdateRequest req)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            customer.FirstName = req.FirstName;
            customer.LastName = req.LastName;
            customer.Email = req.Email;

            await ctx.SaveChangesAsync();

            return Ok("Success");
        }

        #endregion

        #region Card

        //Adding customer credit card.
        [HttpPost("AddCard")]
        public async Task<IActionResult> AddCard(StripeCardRequest stripeCard)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).Include(x => x.CustomerCards).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var stripeCustomerID = customer.StripeCustomerID;
            if (stripeCustomerID == null) return BadRequest("Stripe Customer not found.");

            var isAttached = stripeService.AttachPaymentMethodToCustomer(stripeCard.PaymentMethodID, stripeCustomerID);
            if (isAttached != string.Empty) return BadRequest(isAttached);

            var customerCards = customer.CustomerCards.Where(x => !x.IsRemoved).ToList();

            var customerCard = new CustomerCard()
            {
                CustomerID = customer.CustomerID,
                PaymentMethodID = stripeCard.PaymentMethodID,
                Last4 = stripeCard.Last4,
                ExpirationMonth = stripeCard.ExpirationMonth,
                ExpirationYear = stripeCard.ExpirationYear,
                Brand = stripeCard.Brand,
            };

            await ctx.CustomerCards.AddAsync(customerCard);
            await ctx.SaveChangesAsync();

            if (customerCards.Count() == 0 || stripeCard.IsDefault) customer.DefaultCardID = customerCard.CustomerCardID;
            await ctx.SaveChangesAsync();

            return Ok(await customerManager.GetAllCards(customer.CustomerID));
        }

        [HttpPost("ChangeDefaultCard")]
        public async Task<IActionResult> ChangeDefaultCard(long customerCardID)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var customerCards = await ctx.CustomerCards.Where(x => x.CustomerID == customer.CustomerID && !x.IsRemoved).ToListAsync();

            customer.DefaultCardID = customerCardID;
            await ctx.SaveChangesAsync();
            return Ok(await customerManager.GetAllCards(customer.CustomerID));
        }

        //Removing specific customer Card
        [HttpPost("DeleteCard")]
        public async Task<IActionResult> RemoveCard(long customerCardID)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).Include(x => x.CustomerCards).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            if (customer.DefaultCardID == customerCardID) return BadRequest("Default Card cannot be deleted");
            var customerCards = customer.CustomerCards.Where(x => !x.IsRemoved);
            var customerCard = customerCards.Where(x => x.CustomerCardID == customerCardID).FirstOrDefault();
            if (customerCard == null) return NotFound("Card cannot be found.");
            var cardCount = customerCards.Count();
            if (cardCount == 1) return BadRequest("You need atleast one card");
            var isSuccess = stripeService.RemovePaymentMethodAsync(customerCard.PaymentMethodID);
            if (isSuccess != string.Empty) return BadRequest(isSuccess);

            customerCard.IsRemoved = true;
            await ctx.SaveChangesAsync();
            return Ok(await customerManager.GetAllCards(customer.CustomerID));
        }


        #endregion

        #region Trips
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
        [HttpGet("GetMyCompletedTrips")]
        public async Task<IActionResult> GetCustomerCompletedTrips(int filterType)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Driver information not found.");

            var trips = await tripManager.GetCustomerRecentTrips(customer.CustomerID, filterType);

            var obj = new List<object>();
            foreach (var trip in trips)
            {
                var payment = trip.Payment;
                if (payment == null) return BadRequest("Payment not found");
                var timezoneTime = DbHelper.TimeInTimeZone(payment.CreatedDateTime, customer.TimeZone);
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
            }


            return Ok(obj);
        }
        #endregion

        #region Locations
        /// <summary>
        /// Method <c>GetCustomerSavedLocations</c> retrieves all of a user's saved locations (work, home, favorites)
        /// </summary>

        [HttpGet("GetSavedLocations")]
        public async Task<IActionResult> GetCustomerSavedLocations()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var locations = await ctx.CustomerSavedLocations
                .Include(x => x.GoogleLocation)
                .Select(x => new {
                    x.CustomerID,
                    x.CustomerSavedLocationID,
                    x.Type,
                    x.GoogleLocationID,
                    x.GoogleLocation!.Name,
                    x.GoogleLocation.Address,
                    x.GoogleLocation.Longitude,
                    x.GoogleLocation.Latitude,
                    x.GoogleLocation.LocationType
                })
                .Where(x => x.CustomerID == customer.CustomerID)
                .OrderByDescending(x => x.CustomerSavedLocationID)
                .ToListAsync();

            return Ok(locations);
        }


        /// <summary>
        /// Method <c>AddLocation</c> Adds a new saved location to a user
        /// </summary>
        [HttpPost("AddLocation")]
        public async Task<IActionResult> AddLocation(SavedLocation savedLocation)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var retrievedLocation = await tripManager.GetGoogleLocation(savedLocation.Address, savedLocation.Name, savedLocation.Latitude, savedLocation.Longitude, savedLocation.LocationType);

            var location = await customerManager.SaveLocation(customer.CustomerID, retrievedLocation.GoogleLocationID, savedLocation.Type);

            return Ok(location);
        }

        /// <summary>
        /// Method <c>RemoveLocation</c> removes a user's saved location by its ID
        /// </summary>
        [HttpDelete("RemoveLocation/{googleLocationID:long}")]
        public async Task<IActionResult> RemoveLocation(long googleLocationID)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var location = await ctx.CustomerSavedLocations.Where(x => x.CustomerID == customer.CustomerID && x.GoogleLocationID == googleLocationID).FirstOrDefaultAsync();
            if (location == null) return NotFound("Location Not Found");

            ctx.CustomerSavedLocations.Remove(location);
            await ctx.SaveChangesAsync();

            return Ok("Success");
        }

        /// <summary>
        /// Method <c>ReplaceLocation</c> replaces a user's saved location given its ID
        /// </summary
        [HttpPatch("ReplaceLocation/{googleLocationID:long}")]
        public async Task<IActionResult> ReplaceLocation(long googleLocationID, [FromBody] SavedLocation savedLocation)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var staleLocation = await ctx.CustomerSavedLocations.Where(x => x.CustomerID == customer.CustomerID && x.GoogleLocationID == googleLocationID).FirstOrDefaultAsync();
            if (staleLocation == null) return NotFound("Location Not Found");
            ctx.CustomerSavedLocations.Remove(staleLocation);

            var retrievedLocation = await tripManager.GetGoogleLocation(savedLocation.Address, savedLocation.Name, savedLocation.Latitude, savedLocation.Longitude, savedLocation.LocationType);
            var location = await customerManager.SaveLocation(customer.CustomerID, retrievedLocation.GoogleLocationID, savedLocation.Type);

            await ctx.SaveChangesAsync();

            return Ok(location);
        }

        /// <summary>
        /// Method <c>GetSearchHistories</c> retrieves a user's recent searches
        /// </summary>
        [HttpGet("GetSearchHistory")]
        public async Task<IActionResult> GetSearchHistories()
        {
            //fetch user credentials
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            //fetch customer information
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer information not found.");

            //search for user's search history and return 
            var histories = await ctx.CustomerSearchHistories
                .Include(x => x.GoogleLocation)
                .Select(x => new
                {
                    x.CustomerSearchHistoryID,
                    x.CustomerID,
                    x.GoogleLocation.Name,
                    x.GoogleLocation.Address,
                    x.GoogleLocation.Latitude,
                    x.GoogleLocation.Longitude,
                    x.GoogleLocation.LocationType,
                })

                .Where(x => x.CustomerID == customer.CustomerID)
                .Take(5)
                .OrderByDescending(x => x.CustomerSearchHistoryID)
                .ToListAsync();

            return Ok(histories);
        }

        #endregion

        #region Coupons

        /// <summary>
        /// Method <c>ApplyCoupon</c> adds a coupon to a user's points
        /// </summary>
        [HttpPost("ApplyCoupon")]
        public async Task<IActionResult> ApplyCoupon(CouponRequest couponRequest)
        {
            //fetch user credentials
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            //fetch customer information
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer information not found.");

            //search 
            var coupon = await ctx.Coupons.Where(x => x.Code == couponRequest.CouponCode && x.Active == true).FirstOrDefaultAsync();
            if (coupon == null) return NotFound("Coupon does not exist");

            var pointAddHistory = new PointAddHistory() { CustomerID= customer.CustomerID, Amount = coupon.Amount, PointType = EnumPointType.Coupon };
            ctx.PointAddHistories.Add(pointAddHistory);


            //What happens if two person register coupon at the same time?
            coupon.CustomerID = customer.CustomerID;
            coupon.Active = false;
            customer.Point += coupon.Amount;

            await ctx.SaveChangesAsync();

            return Ok(customer.Point);
        }

        /// <summary>
        /// Method <c>AddPoints</c> adds a coupon to a user's points
        /// </summary>
        [HttpPost("AddPoints")]
        public async Task<IActionResult> AddPoints(PointRequest pointRequest)
        {
            //fetch user credentials
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            //fetch customer information
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer information not found.");

            var customerCard = await ctx.CustomerCards.Where(x => x.CustomerID == customer.CustomerID && x.CustomerCardID == pointRequest.CustomerCardID).FirstOrDefaultAsync();
            if (customerCard == null) return NotFound("Customer Card Not Found");

            //Call strip and add points
            var isSuccess = stripeService.MakePayment(customer.StripeCustomerID, customerCard.PaymentMethodID, pointRequest.Amount, true, out string paymentIntentID);
            if (isSuccess == string.Empty)
            {
                var pointAddHistory = new PointAddHistory() { CustomerID = customer.CustomerID, Amount = pointRequest.Amount, PointType = EnumPointType.Card };
                ctx.PointAddHistories.Add(pointAddHistory);
                customer.Point += pointRequest.Amount;
                await ctx.SaveChangesAsync();
            } else
            {
                return BadRequest(isSuccess);
            }

            return Ok(customer.Point);
        }

        #endregion

        [HttpPost("UpdateLanguage")]
        public async Task<IActionResult> UpdateLanguage(EnumLanguage language)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var existingCustomer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (existingCustomer == null) return NotFound("The Customer information not found.");

            if (existingCustomer.Language != language)
            {
                existingCustomer.Language = language;
                await ctx.SaveChangesAsync();
            }

            return Ok("success");
        }

        #region Misc



        #endregion


    }
}
