using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models.NonDBModels
{
    public class TripInquiry
    {
        public string PickupName { get; set; }
        public string PickupAddress { get; set; }
        public double PickupLongitude { get; set; }
        public double PickupLatitude { get; set; }
        public EnumLocationType PickupLocationType { get; set; } = EnumLocationType.OTHER;

        public string DropoffName { get; set; }
        public string DropoffAddress { get; set; }
        public double DropoffLongitude { get; set; }
        public double DropoffLatitude { get; set; }
        public EnumLocationType DropoffLocationType { get; set; } = EnumLocationType.OTHER;

    }
}
