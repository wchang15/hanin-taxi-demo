using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CompanyGoogleLocation
    {
        public long CompanyGoogleLocationID { get; set; }
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        public long GoogleLocationID { get; set; }
        public long? CompanyID { get; set; }
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
        public virtual GoogleLocation GoogleLocation { get; set; }
        public virtual Company? Company { get; set; }
    }
}
