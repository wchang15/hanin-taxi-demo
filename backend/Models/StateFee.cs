using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class StateFee
    {
        public long StateFeeID { get; set; }
        public EnumState? FromState { get; set; }
        public EnumState? ToState { get; set; }
        public EnumCalculationMethod CalculationMethod { get; set; }
        [MaxLength(50)]
        public string Description { get; set; } = string.Empty;
        public decimal Value { get; set; }
        public EnumLocationType? LocationType { get; set; }

    }
}
