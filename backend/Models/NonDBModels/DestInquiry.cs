using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class DestInquiry
    {
        public string DropoffName { get; set; }
        public string DropoffAddress { get; set; }
        public double DropoffLongitude { get; set; }
        public double DropoffLatitude { get; set; }
        public EnumLocationType DropoffLocationType { get; set; } = EnumLocationType.OTHER;
    }
}
