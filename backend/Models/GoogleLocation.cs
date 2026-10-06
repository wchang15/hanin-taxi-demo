using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class GoogleLocation
    {
        public long GoogleLocationID { get; set; }
        [MaxLength(255)]
        public string Name { get; set; } = string.Empty;
        [MaxLength(500)]
        public string Address { get; set; } = string.Empty;

        [Column(TypeName = "decimal(9,6)")]
        public double Longitude { get; set; }
        [Column(TypeName = "decimal(8,6)")]
        public double Latitude { get; set; }
        public EnumState State { get; set; }
        public EnumLocationType LocationType { get; set; } = EnumLocationType.OTHER;

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual CompanyGoogleLocation? CompanyGoogleLocation { get; set; }

        [NotMapped]
        public string PreferredName { get; set; } = string.Empty; // Only for returning CompanyGoogleLocation
    }
}
