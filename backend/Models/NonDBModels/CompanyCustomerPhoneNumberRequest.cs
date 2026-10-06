using KoreanTaxi.Models.Enums;
using Org.BouncyCastle.Ocsp;

namespace KoreanTaxi.Models.NonDBModels
{
    public class CompanyCustomerPhoneNumberRequest
    {
        public long CompanyCustomerPhoneNumberID { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string LocationName { get; set; } = string.Empty;
        public string LocationAddress { get; set; } = string.Empty;
        public string LocationPreferredName { get; set; } = string.Empty;
        public double LocationLatitude { get; set; }
        public double LocationLongitude { get; set; }
        public EnumLocationType LocationType { get; set; } = EnumLocationType.OTHER;
    }
}