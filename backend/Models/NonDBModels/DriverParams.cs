using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations;

namespace KoreanTaxi.Models.NonDBModels
{
    public class DriverParams
    {
        public long? Id { get; set; }
        // This is about Driver
        public int DriverNumber { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string? Account { get; set; }
        public string? Passwords { get; set; }
        public string? Email { get; set; }
        public string PhoneNumber { get; set; }
        public EnumLanguage Language { get; set; }
        //This is about Taxi
        public EnumTaxiColor Color { get; set; }
        public EnumTaxiMake Make { get; set; }
        public EnumTaxiSize Size { get; set; }
        public string Model { get; set; }
        public string LicensePlate { get; set; }
        public bool TLCApproved { get; set; } 
    }   
}
