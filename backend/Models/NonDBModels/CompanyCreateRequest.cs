using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class CompanyCreateRequest
    {
        public string UserName { get; set; }
        public string Password { get; set; }

        public string PhoneNumber { get; set; }

        public string CompanyName { get; set; }
        public string CompanyContact { get; set; }
        public string Address1 { get; set; }
        public string Address2 { get; set; } = string.Empty;
        public string City { get; set; }
        public string State { get; set; }
        public string Zip { get; set; }

        public string DispatchName { get; set; }

        public List<EnumState> OperatingStates { get; set; }

        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}
