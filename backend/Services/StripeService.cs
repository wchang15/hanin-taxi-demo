using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;
using Microsoft.EntityFrameworkCore;
using Org.BouncyCastle.Crypto.Signers;
using Stripe;

namespace KoreanTaxi.Services
{
    public class StripeService : IStripeService
    {

        private readonly IConfiguration configuration;
        private readonly TaxiDbContext ctx;
        private readonly bool demoMode;
        private readonly string stripeSecretKey;

        public StripeService(IConfiguration configuration, TaxiDbContext ctx)
        {
            this.configuration = configuration;
            this.ctx = ctx;
            demoMode = configuration.GetValue<bool>("DemoMode");
            stripeSecretKey = configuration["Stripe:SecretKey"] ?? configuration["ConnectionStrings:stripeString"] ?? string.Empty;
            StripeConfiguration.ApiKey = stripeSecretKey;
            
        }


        public async Task<string> CreateStripeCustomerAsync(Models.Customer customer)
        {
            if (demoMode || string.IsNullOrWhiteSpace(stripeSecretKey))
            {
                return await Task.FromResult($"demo_customer_{customer.LoginUserID}");
            }

            var ret = string.Empty;
            try
            {
                var addressOptions = new AddressOptions
                {
                    Country = "US"
                };
                var options = new CustomerCreateOptions
                {
                    Email = customer.Email,
                    Name = customer.Fullname,
                    Address = addressOptions,
                    Phone = customer.PhoneNumber
                };
                var service = new CustomerService();
                var stripeCustomer = await service.CreateAsync(options);
                ret = stripeCustomer.Id;
            }
            catch(Exception ex)
            {
            }
            return ret;
        }

        public string RemovePaymentMethodAsync(string paymentMethod)
        {
            if (demoMode) return string.Empty;

            var ret = string.Empty;
            try
            {
                var service = new PaymentMethodService();
                service.Detach(paymentMethod);
            }
            catch (Exception e)
            {
                ret = e.Message;
            }
            return ret;
            
        }

        public string AttachPaymentMethodToCustomer(string paymentMethodID, string stripeCustomerID)
        {
            if (demoMode) return string.Empty;

            var ret = string.Empty;
            try
            {
                var options = new PaymentMethodAttachOptions
                {
                    Customer = stripeCustomerID,
                };
                var service = new PaymentMethodService();
                service.Attach(paymentMethodID,options);
            }
            catch (Exception e)
            {
                ret = e.Message;
            }
            return ret;
        }

        public string MakePayment(string stripeCustomerID, string paymentMethodID, decimal amount, bool capture, out string paymentIntentID)
        {
            var ret = string.Empty;
            long amountInCent = (long)(amount * 100);
            paymentIntentID = string.Empty;
            if (demoMode)
            {
                paymentIntentID = $"demo_payment_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
                return ret;
            }

            try
            {
                var service = new PaymentIntentService();
                var options = new PaymentIntentCreateOptions
                {
                    Amount = amountInCent,
                    Currency = "usd",
                    Customer = stripeCustomerID,
                    PaymentMethod = paymentMethodID,
                    Confirm = true,
                    OffSession= true,
                    CaptureMethod = capture ? "automatic" : "manual"
                };
                var paymentIntent = service.Create(options);
                paymentIntentID = paymentIntent.Id;
            }
            catch (StripeException e)
            {
                ret = "Error code: " + e.StripeError.Code;
            }
            return ret;
        }

        public string CancelPayment(string paymentIntentID)
        {
            if (demoMode) return string.Empty;

            var ret = string.Empty;
            try
            {
                var service = new PaymentIntentService();
                service.Cancel(paymentIntentID);
            }
            catch (StripeException e)
            {
                ret = "Error code: " + e.StripeError.Code;
            }
            return ret;
        }

        public string CompletePayment(Payment payment)
        {
            if (demoMode) return string.Empty;

            var ret = string.Empty;
            if (payment.PaymentIntentID == null) return ret;
            var totalAmount = payment.CardAmount + payment.TipAmount;
            long amountInCent = (long)(totalAmount * 100);
            try
            {
                if (payment.TipAmount == 0)
                {
                    //capture existing payment intent
                    var options = new PaymentIntentCaptureOptions { AmountToCapture = amountInCent };
                    var service = new PaymentIntentService();
                    var test = service.Capture(payment.PaymentIntentID, options);
                }
                else
                {
                    //cancel old intent and create new one
                    CancelPayment(payment.PaymentIntentID);
                    var customerCard = ctx.CustomerCards.Include(x => x.Customer).Where(x => x.CustomerCardID == payment.CustomerCardID).FirstOrDefault();
                    if (customerCard?.Customer == null) return "Payment method not found.";
                    MakePayment(customerCard.Customer.StripeCustomerID, customerCard.PaymentMethodID, totalAmount, true, out string paymentIntentID);
                }
            }
            catch (Exception e)
            {
                CancelPayment(payment.PaymentIntentID);
                var customerCard = ctx.CustomerCards.Include(x => x.Customer).Where(x => x.CustomerCardID == payment.CustomerCardID).FirstOrDefault();
                if (customerCard?.Customer == null) return "Payment method not found.";
                MakePayment(customerCard.Customer.StripeCustomerID, customerCard.PaymentMethodID, totalAmount, true, out string paymentIntentID);
            }

            return ret;
        }

        public string RefundPayment(string paymentIntentID)
        {
            if (demoMode) return string.Empty;

            var ret = string.Empty;
            try
            {
                var options = new RefundCreateOptions
                {
                    PaymentIntent = paymentIntentID,
                };
                var service = new RefundService();
                service.Create(options);
            }
            catch (Exception e)
            {
                ret = e.Message;
            }

            return ret;
        }


    }
}


// MCC 4121
// acct_1MNibPQ8NZauZsMc
