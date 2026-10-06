using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class DriverRating
    {
        public long DriverRatingID { get; set; }
        public long DriverID { get; set; }
        public long CustomerID { get; set; }
        public int Rating { get; set; }
        public long TripID { get; set; }
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Driver? Driver { get; set; }
        public virtual Customer? Customer { get; set; }
        public virtual Trip? Trip { get; set; }
    }
}
