
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class Coupon
    {
        public long CouponID { get; set; }
        public long? CustomerID { get; set; } //Customer who used the coupon
        [MaxLength(50)]
        public string Code { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public bool Active { get; set; }
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    }
}