using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace KoreanTaxi.Models.NonDBModels
{
    public class StripeCardRequest
    {
        public string PaymentMethodID { get; set; }
        public string Last4 { get; set; }
        public int ExpirationMonth { get; set; }
        public int ExpirationYear { get; set; }
        public string Brand { get; set; }
        public bool IsDefault { get; set; } = false;


    }
}
