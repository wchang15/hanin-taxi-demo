using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CompanyFrequentLocation
    {
        public long CompanyFrequentLocationID { get; set; }
        public long CompanyID { get; set; }
        public long GoogleLocationID { get; set; }
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Company Company { get; set; }
        public virtual GoogleLocation GoogleLocation {get; set;}
    }
}
