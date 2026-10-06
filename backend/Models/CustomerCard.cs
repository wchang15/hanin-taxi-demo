using Stripe;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CustomerCard
    {
        public long CustomerCardID { get; set; }
        public long CustomerID { get; set; }
        [MaxLength(255)]
        public string PaymentMethodID { get; set; }
        [MaxLength(50)]
        public string Last4 { get; set; }
        public int ExpirationMonth { get; set; }
        public int ExpirationYear { get; set; }
        [MaxLength(50)]
        public string Brand { get; set; }
        public bool IsRemoved { get; set; } = false;

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Customer? Customer { get; set; }

    }
}
