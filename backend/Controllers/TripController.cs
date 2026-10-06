using KoreanTaxi.Data;
using KoreanTaxi.Helper;
using KoreanTaxi.Managers;
//using KoreanTaxi.Migrations;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure.Internal;
using Stripe;
using System.ComponentModel;
using Twilio.Jwt.AccessToken;
using Twilio.TwiML.Voice;
using USAddress;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TripController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;
        private readonly IBingService bingService;
        private readonly IStripeService stripeService;
        private readonly TripManager tripManager;
        private readonly CustomerManager customerManager;
        private readonly DriverManager driverManager;
        private readonly ITollService tollService;
        private readonly HubManager hubManager;

        public TripController(TaxiDbContext ctx, IUserService userService, IBingService bingService, IStripeService stripeService, TripManager tripManager, CustomerManager customerManager, DriverManager driverManager, ITollService tollService, HubManager hubManager)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.bingService = bingService;
            this.stripeService = stripeService;
            this.tripManager = tripManager;
            this.customerManager = customerManager;
            this.driverManager = driverManager;
            this.tollService = tollService;
            this.hubManager = hubManager;
        }

        /// <summary>
        /// Customer is searching for a new trip.
        /// Trip record gets created.
        /// </summary>
        /// <param name="tripInquiry"></param>
        /// <returns></returns>
        [HttpPost("NewTrip"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> NewTrip(TripInquiry tripInquiry)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip != null) return BadRequest("Already have an active trip.");

            var savedPickupLocation = await tripManager.GetGoogleLocation(tripInquiry.PickupAddress, tripInquiry.PickupName, tripInquiry.PickupLatitude, tripInquiry.PickupLongitude, tripInquiry.PickupLocationType);
            var savedDropoffLocation = await tripManager.GetGoogleLocation(tripInquiry.DropoffAddress, tripInquiry.DropoffName, tripInquiry.DropoffLatitude, tripInquiry.DropoffLongitude, tripInquiry.DropoffLocationType);


            var newTrip = new Trip(customer.CustomerID, null, savedPickupLocation.GoogleLocationID, savedDropoffLocation.GoogleLocationID);

            var sameTrip = await tripManager.GetSameTrip(newTrip);
            if (sameTrip != null)
            {
                newTrip.MileageAmount = sameTrip.MileageAmount;
                newTrip.Mileage = sameTrip.Mileage;
                newTrip.TollAmount = sameTrip.TollAmount;
            }
            else
            {
                var route = await bingService.GetRoute(savedPickupLocation, savedDropoffLocation);
                if (route == null) return BadRequest("Route cannot be found.");

                decimal tollAmount = 0;
                var stateDefaultLocation = await ctx.StateDefaultLocations.Where(x => x.State == savedPickupLocation.State).FirstOrDefaultAsync();
                if (stateDefaultLocation != null)
                {
                    var start = new LatLng(stateDefaultLocation.Latitude, stateDefaultLocation.Longitude);
                    var pickup = new LatLng(savedPickupLocation.Latitude, savedPickupLocation.Longitude);
                    var dropoff = new LatLng(savedDropoffLocation.Latitude, savedDropoffLocation.Longitude);
                    var totalToll = await tollService.GetTollWaypoints(new List<LatLng> { start, start, pickup, dropoff });
                    tollAmount += totalToll;
                }
                else if (route.IsToll)
                {
                    //Find toll TOLL Guru (For Trip)
                    var tripToll = await tollService.GetToll(savedPickupLocation, savedDropoffLocation);
                    tollAmount += tripToll;
                }
                newTrip.TollAmount = tollAmount;
                newTrip.MileageAmount = route.Amount;
                newTrip.Mileage = route.Distance;

            }


            await ctx.Trips.AddAsync(newTrip);
            await ctx.SaveChangesAsync();

            var stateFees = await ctx.StateFees.Where(x => x.FromState == null || x.FromState == newTrip.PickupLocation.State)
                                                   .Where(x => x.ToState == null || x.ToState == newTrip.DropoffLocation.State)
                                                   .ToListAsync();

            foreach (var stateFee in stateFees)
            {
                decimal smallFee = 0;
                decimal largeFee = 0;
                if (stateFee.CalculationMethod == EnumCalculationMethod.MULTIPLY)
                {
                    smallFee = (newTrip.MileageAmount + newTrip.TollAmount) * (decimal)(stateFee.Value / 100);
                    largeFee = (newTrip.MileageAmount + newTrip.TollAmount + Constants.LARGE_TAXI_ADDER) * (decimal)(stateFee.Value / 100);
                }
                else if (stateFee.CalculationMethod == EnumCalculationMethod.ADD)
                {
                    smallFee = stateFee.Value;
                    largeFee = stateFee.Value;
                }
                newTrip.SmallStateFeeAmount += smallFee;
                newTrip.LargeStateFeeAmount += largeFee;
                var tripPriceDetail = new TripPriceDetail()
                {
                    StateFeeID = stateFee.StateFeeID,
                    TripID = newTrip.TripID,
                    SmallAmount = smallFee,
                    LargeAmount = largeFee,
                };
                await ctx.TripPriceDetails.AddAsync(tripPriceDetail);
                await ctx.SaveChangesAsync();
            }

            await customerManager.AddSearchHistory(customer.CustomerID, savedDropoffLocation.GoogleLocationID);

            var fee = new
            {
                smallTaxiFee = newTrip.SmallTaxiFee.ToString("C", Constants.USCULTURE),
                LargeTaxiFee = newTrip.LargeTaxiFee.ToString("C", Constants.USCULTURE),
                tripID = newTrip.TripID,
            };

            return Ok(fee);
        }

        /// <summary>
        /// Customer confirmed the searched trip and calling the taxi.
        /// Customer makes pending payment and gets on the queue.
        /// </summary>
        /// <param name="confirmTripModel"></param>
        /// <returns></returns>
        [HttpPost("ConfirmTrip"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> ConfirmTrip(ConfirmTripModel confirmTripModel)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            if (customer.StripeCustomerID == null) return NotFound("Stripe Customer doesn't Exist");
            var trip = await tripManager.GetFindFareTrip(customer.CustomerID, confirmTripModel.TripID);
            if (trip == null) return BadRequest("Trip Not Found");
            var customerCard = await ctx.CustomerCards.Where(x => x.CustomerID == customer.CustomerID && x.CustomerCardID == confirmTripModel.CustomerCardID).FirstOrDefaultAsync();
            if (customerCard == null && confirmTripModel.CustomerCardID != 0) return NotFound("Card cannot be found.");

            var totalAmount = confirmTripModel.EnumTaxiSize == EnumTaxiSize.SMALL ? trip.SmallTaxiFee : trip.LargeTaxiFee;
            //Make Payment
            var payment = new Payment();
            payment.TripID = confirmTripModel.TripID;
            payment.CustomerCardID = confirmTripModel.CustomerCardID;
            payment.PaymentType = confirmTripModel.EnumPaymentType;
            payment.PointAmount = 0;

            if (payment.PaymentType == EnumPaymentType.CASH)
            {
                payment.CashAmount = totalAmount;
            }

            if (payment.PaymentType == EnumPaymentType.POINTCARD && customer.Point == 0)
            {
                payment.PaymentType = EnumPaymentType.CARD;
            }

            if (payment.PaymentType == EnumPaymentType.POINTCARD)
            {
                var amountMinusPoint = totalAmount - customer.Point;
                if (amountMinusPoint > 0)
                {
                    totalAmount = amountMinusPoint;
                    payment.PointAmount = customer.Point;
                    customer.Point = 0;
                }
                else if (amountMinusPoint == 0)
                {
                    totalAmount = amountMinusPoint;
                    payment.PointAmount = customer.Point;
                    customer.Point = 0;
                    payment.PaymentType = EnumPaymentType.POINT;
                }
                else if (amountMinusPoint < 0)
                {
                    payment.PointAmount = totalAmount;
                    totalAmount = 0;
                    customer.Point = Math.Abs(amountMinusPoint);
                    payment.PaymentType = EnumPaymentType.POINT;
                }

            }

            if (payment.PaymentType == EnumPaymentType.CARD || payment.PaymentType == EnumPaymentType.POINTCARD)
            {
                if (totalAmount > 0)
                {
                    var isSuccess = stripeService.MakePayment(customer.StripeCustomerID, customerCard.PaymentMethodID, totalAmount, false, out string paymentIntentID);
                    if (isSuccess != string.Empty) return BadRequest(isSuccess);
                    if (string.IsNullOrWhiteSpace(paymentIntentID)) return BadRequest("Payment Intent Not Created");
                    payment.PaymentIntentID = paymentIntentID;
                    payment.CardAmount = totalAmount;
                }
            }
            await ctx.Payments.AddAsync(payment);
            trip.CalledTaxiSize = confirmTripModel.EnumTaxiSize;
            trip.TripStatus = EnumTripStatus.MATCHING;
            await ctx.SaveChangesAsync();

            var customerQueue = new CustomerQueue(customer.CustomerID, null, trip.TripID);
            await ctx.CustomerQueues.AddAsync(customerQueue);
            await ctx.SaveChangesAsync();


            return Ok("Success");
        }

        /// <summary>
        /// Gets the current trip for customer.
        /// </summary>
        /// <returns></returns>
        [HttpGet("CurrentTripCustomer"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> GetCurrentTripCustomer()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return BadRequest("Working Trip Not Found");

            var ret = new
            {
                trip = await tripManager.TripReturnForCustomer(trip)
            };

            return Ok(ret);
        }

        /// <summary>
        /// Gets the current trip for driver.
        /// </summary>
        /// <returns></returns>
        [HttpGet("CurrentTripDriver"), Authorize(Roles = nameof(EnumUserRole.DRIVER))]
        public async Task<IActionResult> GetCurrentTripDriver()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var trip = await tripManager.GetCurrentTripDriver(driver.DriverID);
            if (trip == null) return BadRequest("Working Trip Not Found");

            var ret = new
            {
                trip = await tripManager.TripReturnForCustomer(trip)
            };

            // todo: should return queue when trip does not exist but queue does.

            return Ok(ret);
        }

        //This will get called every 5 second from the client
        [HttpGet("TripStatus"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> GetTripStatusCustomer()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return BadRequest("Working Trip Not Found");


            return Ok(trip.TripStatus);
        }

        /// <summary>
        /// Getting the matched driver for customer
        /// </summary>
        /// <returns></returns>
        [HttpGet("TripDriver"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> GetTripDriver()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return BadRequest("Working Trip Not Found");
            if (trip.DriverID == null) return NotFound("Driver is not found");

            var driver = await driverManager.GetDriverByID(trip.DriverID.Value);
            if (driver == null) return NotFound("Driver is not found");
            var taxi = driver.Taxi;

            var ret = new
            {
                licensePlate = taxi.LicensePlate,
                carModel = taxi.Model,
                carColor = DbHelper.GetDescription(taxi.Color),
                companyName = driver.Company.Name,
                driverName = driver.DriverNumber.ToString(),
                phoneNumber = driver.PhoneNumber
            };
            return Ok(ret);
        }

        //Getting the matched driver location
        [HttpGet("TripDriverLocation"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> GetTripDriverLocation()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return BadRequest("Working Trip Not Found");
            if (trip.DriverID == null) return NotFound("Driver is not found");

            var driverQueue = await driverManager.GetDriverQueueByDriverID(trip.DriverID.Value);
            if (driverQueue == null) return NotFound("Driver is not found");

            var ret = new LatLng(driverQueue.Latitude, driverQueue.Longitude);

            return Ok(ret);
        }

        /// <summary>
        /// When driver clicked trip start on their app.
        /// Changing the trip status.
        /// </summary>
        /// <returns></returns>
        [HttpPost("StartTrip"), Authorize(Roles = nameof(EnumUserRole.DRIVER))]
        public async Task<IActionResult> TripStarted(DestInquiry dest)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");

            var driverQueue = await driverManager.GetDriverQueueByDriverID(driver.DriverID);
            if (driverQueue == null) return NotFound("Driver Queue not found");

            var trip = await ctx.Trips.Include(x => x.PickupLocation).ThenInclude(x => x.CompanyGoogleLocation).Where(x => x.TripID == driverQueue.TripID && x.DriverID == driver.DriverID && x.TripStatus == EnumTripStatus.PICKINGUPCUSTOMER).FirstOrDefaultAsync();
            if (trip == null) return NotFound("Waiting Trip is not Found.");

            decimal tripAmount = 0;

            if (!String.IsNullOrEmpty(dest.DropoffName))
            {
                var savedDropoffLocation = await tripManager.GetGoogleLocation(dest.DropoffAddress, dest.DropoffName, dest.DropoffLatitude, dest.DropoffLongitude, dest.DropoffLocationType);
                trip.DropoffLocationID = savedDropoffLocation.GoogleLocationID;

                if (trip.TripType == EnumTripType.CASH || trip.TripType == EnumTripType.ALCOHOL1 || trip.TripType == EnumTripType.ALCOHOL2)
                {
                    var presetAmount = await ctx.CompanyTripPrices.Where(x => x.CompanyID == trip.CompanyID).ToListAsync();

                    foreach (var p in presetAmount)
                    {
                        if (tripManager.IsAddressCity(trip.PickupLocation.Address, p.FromCity) && tripManager.IsAddressCity(dest.DropoffAddress, p.ToCity))
                        {
                            // if alcohol trip drivers get double amount else same
                            if (trip.TripType == EnumTripType.ALCOHOL1 || trip.TripType == EnumTripType.ALCOHOL2)
                            {
                                tripAmount = p.Price * 2;
                            } else
                            {
                                tripAmount = p.Price;
                            }
                            trip.CompanyTripAmount = tripAmount;
                            //Notify Company of this amount
                            break;
                        }
                    }
                }

                if (trip.TripType == EnumTripType.ALCOHOL1)
                {
                    var alcohol2Trip = await ctx.Trips.Where(x => x.TripID == trip.AlcoholTripID).FirstOrDefaultAsync();
                    if (alcohol2Trip != null)
                    {
                        alcohol2Trip.DropoffLocationID = savedDropoffLocation.GoogleLocationID;
                        if (alcohol2Trip.DriverID != null) alcohol2Trip.TripStatus = EnumTripStatus.GOINGTODEST;
                        //alcohol2Trip.TripStatus = EnumTripStatus.GOINGTODEST;
                        alcohol2Trip.CompanyTripAmount = tripAmount;
                        await ctx.SaveChangesAsync();
                        var tripReturnForDriver2 = await tripManager.TripReturnForDriver(alcohol2Trip);
                        await hubManager.SendToClient($"{Constants.DRIVER}{alcohol2Trip.DriverID}", Constants.TRIPSTART, alcohol2Trip.TripStatus, tripReturnForDriver2);

                        if (alcohol2Trip.DriverID != null)
                        {
                            var tripReturnForCompany2 = await tripManager.GetCurrentTripCompany(alcohol2Trip);
                            await hubManager.SendToClient($"{Constants.COMPANY}{alcohol2Trip.CompanyID}", Constants.TRIPSTART, tripReturnForCompany2.TripStatus, tripReturnForCompany2);
                        }

                    }
                }
            }

            trip.TripStatus = EnumTripStatus.GOINGTODEST;

            await ctx.SaveChangesAsync();

            if (trip.CustomerID != null)
            {
                var tripReturnForCustomer = await tripManager.TripReturnForCustomer(trip);
                await hubManager.SendToClient($"{Constants.CUSTOMER}{trip.CustomerID}", Constants.TRIPSTART, trip.TripStatus);
            }
            else if (trip.CompanyID != null)
            {
                var tripReturnForCompany = await tripManager.GetCurrentTripCompany(trip);
                await hubManager.SendToClient($"{Constants.COMPANY}{trip.CompanyID}", Constants.TRIPSTART, tripReturnForCompany.TripStatus, tripReturnForCompany);
            }

            return Ok(tripAmount);
        }

        /// <summary>
        /// When driver clicked trip complete on their app.
        /// Changing the trip status.
        /// Removing the driver queue.
        /// </summary>
        /// <returns></returns>
        [HttpPost("CompleteTrip"), Authorize(Roles = nameof(EnumUserRole.DRIVER))]
        public async Task<IActionResult> TripCompleted()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");

            var driverQueue = await driverManager.GetDriverQueueByDriverID(driver.DriverID);
            if (driverQueue == null) return NotFound("Driver Queue not found");

            var trip = await ctx.Trips.Include(x => x.PickupLocation).ThenInclude(x => x.CompanyGoogleLocation).Where(x => x.TripID == driverQueue.TripID && x.DriverID == driver.DriverID && x.TripStatus == EnumTripStatus.GOINGTODEST).FirstOrDefaultAsync();
            if (trip == null) return NotFound("Moving Trip is not Found.");
            trip.TripStatus = EnumTripStatus.COMPLETED;
            trip.CompletedTime = DateTime.UtcNow;

            await driverManager.RemoveFromQueue(driver.DriverID, false);

            //await driverManager.ReAddDriverToQueue(driver.DriverID);

            await ctx.SaveChangesAsync();

            if (trip.CustomerID != null)
            {
                var tripReturnForCustomer = await tripManager.TripReturnForCustomer(trip);
                await hubManager.SendToClient($"{Constants.CUSTOMER}{trip.CustomerID}", Constants.TRIPCOMPLETE, trip.TripStatus);
            }
            else if (trip.CompanyID != null)
            {
                var tripReturnForCompany = await tripManager.GetCurrentTripCompany(trip);
                await hubManager.SendToClient($"{Constants.COMPANY}{trip.CompanyID}", Constants.TRIPCOMPLETE, tripReturnForCompany.TripStatus, tripReturnForCompany);
            }
            return Ok(trip);
        }

        /// <summary>
        /// When customer canceled the trip.
        /// Customer pays 25% of the amount if the driver is matched. Removes customer from queue
        /// </summary>
        /// <returns></returns>
        [HttpPost("CustomerCancel"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> CustomerCancelTrip()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return NotFound("Trip Not Found");
            var payment = trip.Payment;
            if (payment == null) return BadRequest("Payments not found.");

            var quarterAmount = payment.FullAmount / 4;
            var fee = quarterAmount > 3 ? quarterAmount : 3;

            if (trip.DriverID != null)
            {
                if (payment.PointAmount >= fee)
                {
                    var returnPoint = payment.PointAmount - fee;
                    payment.PointAmount = fee;
                    payment.CardAmount = 0;
                    customer.Point += returnPoint;
                    if (payment.CardAmount > 0) stripeService.CancelPayment(payment.PaymentIntentID);
                }
                else
                {
                    customer.Point += payment.PointAmount;
                    payment.CardAmount = fee;
                    payment.PointAmount = 0;
                    var isSuccess = stripeService.CompletePayment(payment);
                    if (isSuccess != string.Empty) return BadRequest("Payment Failed.");
                }
                payment.PaymentStatus = EnumPaymentStatus.PAID;

                var driverQueue = await driverManager.GetDriverQueueByDriverID(trip.DriverID.Value);
                if (driverQueue == null) return NotFound("Driver Queue Not Found");

                driverQueue.QueueStatus = EnumQueueStatus.CUSTOMERCANCELED;
                driverQueue.TripID = null;
                driverQueue.CustomerQueueID = null;

                await hubManager.SendToClient($"{Constants.DRIVER}{trip.DriverID}", Constants.CUSTOMERCANCEL, EnumTripStatus.CUSTOMERCANCELED, trip.TripID);

            }
            else
            {
                if (payment.PointAmount > 0)
                {
                    customer.Point += payment.PointAmount;
                }
                if (payment.CardAmount > 0)
                {
                    //Stripe uncapture
                    stripeService.CancelPayment(payment.PaymentIntentID);
                }
                payment.PaymentStatus = EnumPaymentStatus.CANCELED;
                //ctx.Payments.Remove(payment);
            }

            trip.TripStatus = EnumTripStatus.CUSTOMERCANCELED;
            await tripManager.RemoveCustomerQueue(customer.CustomerID);
            await ctx.SaveChangesAsync();

            return Ok("Success");
        }

        /// <summary>
        /// Driver canceled the trip.
        /// If Airport cancel -> both customer and driver look for another match
        /// If not -> customer queue is canceled. driver looks for another match
        /// </summary>
        /// <returns></returns>
        [HttpPost("DriverCancel"), Authorize(Roles = nameof(EnumUserRole.DRIVER))]
        public async Task<IActionResult> DriverCancelTrip()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var driver = await driverManager.GetDriverByLoginUserID(userID.Value);
            if (driver == null) return NotFound("The Driver information not found.");
            var driverQueue = await ctx.DriverQueues.Where(x => x.DriverID == driver.DriverID && x.QueueStatus == EnumQueueStatus.ACCEPTED).FirstOrDefaultAsync();
            if (driverQueue == null) return BadRequest("Driver doesn't have a accepted queue.");
            var trip = await ctx.Trips.Include(x => x.PickupLocation).ThenInclude(x => x.CompanyGoogleLocation).Include(x => x.Payment).Where(x => x.TripID == driverQueue.TripID
                                   && x.TripStatus == EnumTripStatus.PICKINGUPCUSTOMER).FirstOrDefaultAsync();
            if (trip == null) return BadRequest("Waiting Trip Not Found");
            var customerQueue = await ctx.CustomerQueues.Where(x => x.TripID == trip.TripID && x.CustomerQueueID == driverQueue.CustomerQueueID && x.QueueStatus == EnumQueueStatus.ACCEPTED).FirstOrDefaultAsync();
            if (customerQueue == null) return BadRequest("Customer Queue not found");

            if (customerQueue.CompanyID != null)
            {
                // Call Taxi
                trip.TripStatus = EnumTripStatus.MATCHING;
                trip.DriverID = null;
                customerQueue.QueueStatus = EnumQueueStatus.WAITING;
            }
            else
            {
                // App Taxi
                customerQueue.QueueStatus = EnumQueueStatus.DRIVERCANCELED;
                trip.TripStatus = EnumTripStatus.DRIVERCANCELED;
            }

            if (trip.TripType == EnumTripType.ALCOHOL1 || trip.TripType == EnumTripType.ALCOHOL2)
            {
                var otherAlcoholTrip = await ctx.Trips.Include(x => x.Driver).Where(x => x.TripID == trip.AlcoholTripID).FirstOrDefaultAsync();
                if (otherAlcoholTrip != null && otherAlcoholTrip.DriverID != null)
                {
                    await hubManager.SendToClient($"{Constants.DRIVER}{otherAlcoholTrip.DriverID}", Constants.ALCOHOLDRIVERMATCH, otherAlcoholTrip.TripID, "");
                }
            }

            var driverQueueRejectedCustomerQueue = new DriverQueueRejectedCustomerQueue() { DriverQueueID = driverQueue.DriverQueueID, CustomerQueueID = driverQueue.CustomerQueueID ?? 0 };
            await ctx.DriverQueueRejectedCustomerQueues.AddAsync(driverQueueRejectedCustomerQueue);
            driverQueue.QueueStatus = EnumQueueStatus.WAITING;
            driverQueue.TripID = null;
            driverQueue.CustomerQueueID = null;


            //var driverQueueRejectedCustomerQueues = ctx.DriverQueueRejectedCustomerQueues.Where(x => x.DriverQueueID == driverQueue.DriverQueueID);
            //ctx.DriverQueueRejectedCustomerQueues.RemoveRange(driverQueueRejectedCustomerQueues);
            //ctx.DriverQueues.Remove(driverQueue);

            await ctx.SaveChangesAsync();

            if (trip.CustomerID != null)
            {
                await hubManager.SendToClient($"{Constants.CUSTOMER}{trip.CustomerID}", Constants.DRIVERCANCEL, trip.TripStatus);
            }
            else if (trip.CompanyID != null)
            {
                var tripReturnForCompany = await tripManager.GetCurrentTripCompany(trip);
                await hubManager.SendToClient($"{Constants.COMPANY}{trip.CompanyID}", Constants.DRIVERCANCEL, tripReturnForCompany.TripStatus, tripReturnForCompany);
            }




            return Ok("Success");
        }

        /// <summary>
        /// When driver canceled and the customer does not respond, customer pays the full amount.
        /// </summary>
        /// <returns></returns>
        [HttpPost("RemoveCustomerQueue"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> RemoveCustomerQueue()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var customerQueue = ctx.CustomerQueues.Where(x => x.CustomerID == customer.CustomerID);
            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return BadRequest("Trip not found");

            var payment = trip.Payment;
            if (payment == null) return BadRequest("Payments not found.");
            var isSuccess = stripeService.CompletePayment(payment);
            if (isSuccess == string.Empty)
            {
                payment.PaymentStatus = EnumPaymentStatus.PAID;
            }

            ctx.RemoveRange(customerQueue);
            await ctx.SaveChangesAsync();

            return Ok("Success");
        }

        /// <summary>
        /// When driver canceled and the customer can get a new match without penalty fee
        /// </summary>
        /// <returns></returns>
        [HttpPost("RematchCustomerQueue"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> RematchCustomerQueue()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var customerQueue = await ctx.CustomerQueues.Where(x => x.CustomerID == customer.CustomerID && x.QueueStatus == EnumQueueStatus.DRIVERCANCELED).FirstOrDefaultAsync();
            if (customerQueue == null) return NotFound("Customer Queue not found");

            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return BadRequest("Trip not found");

            trip.DriverID = null;
            trip.TripStatus = EnumTripStatus.MATCHING;

            customerQueue.QueueStatus = EnumQueueStatus.WAITING;
            await ctx.SaveChangesAsync();


            return Ok("Success");
        }


        //rate driver
        [HttpPost("DriverRating"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> RateDriver(int tripID, int rating)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var trip = await tripManager.GetTripByID(tripID);
            if (trip == null) return BadRequest("Working Trip Not Found");
            if (trip.DriverID == null) return NotFound("Driver is not found");

            var driverRating = new DriverRating() { DriverID = trip.DriverID.Value, CustomerID = customer.CustomerID, Rating = rating, TripID = tripID };

            await ctx.DriverRatings.AddAsync(driverRating);
            await ctx.SaveChangesAsync();

            return Ok("Success");
        }

    }
}
