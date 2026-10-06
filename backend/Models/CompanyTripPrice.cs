using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CompanyTripPrice
    {
        public long CompanyTripPriceID { get; set; }
        [MaxLength(50)]
        public string FromCity { get; set; } = string.Empty;
        [MaxLength(50)]
        public string ToCity { get; set; } = string.Empty;
        public long CompanyID { get; set; }
        public decimal Price { get; set; }

        public virtual Company Company { get; set; }
    }
}
