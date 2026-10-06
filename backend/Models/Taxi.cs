using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations;

namespace KoreanTaxi.Models
{
    public class Taxi
    {
        public long TaxiID { get; set; }
        public EnumTaxiColor Color { get; set; }
        public EnumTaxiMake Make { get; set; }
        [MaxLength(50)]
        public string Model { get; set; }
        [MaxLength(50)]
        public string LicensePlate { get; set; }
        public EnumTaxiSize Size { get; set; }
        public long? DriverID { get; set; }

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
        public virtual Driver? Driver { get; set; }

    }
}