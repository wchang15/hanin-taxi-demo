using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models.NonDBModels
{
    public class CompanyTripInquiry
    {
        public string PickupName { get; set; }
        public string PickupAddress { get; set; }
        public double PickupLongitude { get; set; }
        public double PickupLatitude { get; set; }
        public string? Notes { get; set; }
        public EnumLocationType LocationType { get; set; } = EnumLocationType.OTHER;
        public string? CustomerPhoneNumber { get; set; }
        public EnumTaxiSize EnumTaxiSize { get; set; }
        public EnumTripType EnumTripType { get; set; }


    }
}
