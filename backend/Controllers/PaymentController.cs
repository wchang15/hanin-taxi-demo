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
using Microsoft.EntityFrameworkCore.Migrations.Operations;
using Stripe;

namespace KoreanTaxi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;
        private readonly TripManager tripManager;
        private readonly CustomerManager customerManager;
        private readonly IStripeService stripeService;

        public PaymentController(TaxiDbContext ctx, IUserService userService, IStripeService stripeService, TripManager tripManager, CustomerManager customerManager)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.tripManager = tripManager;
            this.customerManager = customerManager;
            this.stripeService = stripeService;
        }


        [HttpPost("Refunding/{id:long}")]
        public async Task<IActionResult> MarkRefund(long id)
        {
            var payment = await ctx.Payments.FindAsync(id);

            if (payment == null) return NotFound();
            payment.PaymentStatus = EnumPaymentStatus.REFUNDING;
            await ctx.SaveChangesAsync();
            return Ok(payment);
        }

        [HttpPost("CompletePayment"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER))]
        public async Task<IActionResult> Complete(decimal tip = 0)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");
            var trip = await tripManager.GetCurrentTripCustomer(customer.CustomerID);
            if (trip == null) return BadRequest("Working Trip Not Found");
            if (trip.CustomerID != customer.CustomerID) return BadRequest("Customer is different");
            var payment = trip.Payment;
            if (payment == null) return NotFound("Payment Not Found.");
            if (payment.TipAmount != 0) return BadRequest("Tip Already Added to this trip.");

            payment.TipAmount = tip;

            if (payment.PaymentType == EnumPaymentType.CARD || payment.PaymentType == EnumPaymentType.POINTCARD)
            {
                //used card or point and card
                var isSuccess = stripeService.CompletePayment(payment);
                if (isSuccess != string.Empty) return BadRequest(isSuccess);
            }
            else if (payment.PaymentType == EnumPaymentType.POINT && tip > 0)
            {
                if (customer.Point >= tip)
                {
                    customer.Point -= tip;
                }
                else
                {
                    var defaultCard = await ctx.CustomerCards.Where(x => x.CustomerCardID == customer.DefaultCardID).FirstOrDefaultAsync();
                    if (defaultCard == null) return BadRequest("A payment card is required for this tip.");

                    var isSuccess = stripeService.MakePayment(customer.StripeCustomerID, defaultCard.PaymentMethodID, tip, true, out var paymentIntentID);
                    if (isSuccess != string.Empty) return BadRequest(isSuccess);
                }
            }

            payment.PaymentStatus = EnumPaymentStatus.PAID;

            //remove customerqueue
            var cq = ctx.CustomerQueues.Where(x => x.CustomerID == customer.CustomerID);
            ctx.CustomerQueues.RemoveRange(cq);
            

            await ctx.SaveChangesAsync();

            return Ok(payment);
        }


    }
}
