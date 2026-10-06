using KoreanTaxi.Models.Enums;
using Stripe;

namespace KoreanTaxi.Models.NonDBModels
{
    public class DriverReturn
    {

        public DriverReturn(Driver driver) { 
            DriverID = driver.DriverID;
            FirstName= driver.FirstName;
            LastName= driver.LastName;
            DriverNumber = driver.DriverNumber;
            DOB = driver.DOB;
            Email= driver.Email;
            PhoneNumber= driver.PhoneNumber;
            CompanyName = driver.Company?.Name ?? string.Empty;
            Color = driver.Taxi?.Color.ToString() ?? string.Empty;
            Make = driver.Taxi?.Make.ToString() ?? string.Empty;
            Size = driver.Taxi?.Size ?? EnumTaxiSize.SMALL;
            Model = driver.Taxi?.Model ?? string.Empty;
            LicensePlate = driver.Taxi?.LicensePlate?.ToString() ?? string.Empty;
            Language = driver.Language;
            Map = driver.Map;
            FrequentLocations = new List<UserLocation>();
        }

        public long DriverID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int DriverNumber { get; set; }
        public DateTime? DOB { get; set; }
        public string? Email { get; set; }
        public string PhoneNumber { get; set; }
        public string CompanyName { get; set; }
        public string Color { get; set; }
        public string Make { get; set; }
        public string Model { get; set; }
        public string LicensePlate { get; set; }
        public EnumTaxiSize Size { get; set; }
        public EnumLanguage Language { get; set; }
        public decimal EarnedToday { get; set; }
        public string Map { get; set; }
        public List<UserLocation>? FrequentLocations { get; set; }


    }
}
