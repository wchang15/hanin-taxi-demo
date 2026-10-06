using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class TripPriceDetail
    {
        public long TripPriceDetailID { get; set; }
        public long StateFeeID { get; set; }
        public long TripID { get; set; }
        public decimal SmallAmount { get; set; } = 0;
        public decimal LargeAmount { get; set; } = 0;


        public virtual StateFee StateFee { get; set; }
        public virtual Trip Trip { get; set; }
    }
}
