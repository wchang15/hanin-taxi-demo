using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;

namespace KoreanTaxi.Services
{
    public interface IStripeService
    {
        public Task<string> CreateStripeCustomerAsync(Models.Customer customer);
        public string RemovePaymentMethodAsync(string paymentMethod);
        public string AttachPaymentMethodToCustomer(string paymentMethodID, string stripeCustomerID);
        public string MakePayment(string stripeCustomerID, string paymentMethodID, decimal amount, bool capture, out string paymentIntentID);
        public string CancelPayment(string paymentIntentID);
        public string CompletePayment(Payment payment);
        public string RefundPayment(string paymentIntentID);

    }
}
