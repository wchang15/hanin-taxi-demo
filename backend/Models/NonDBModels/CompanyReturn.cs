using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations;

namespace KoreanTaxi.Models.NonDBModels
{
    public class CompanyReturn
    {

        public CompanyReturn(CompanyUser companyUser)
        {
            CompanyID = companyUser.CompanyID;
            Name = companyUser.Company.Name;
            PhoneNumber= companyUser.Company.PhoneNumber;
            ContactName= companyUser.Name;
            Address1= companyUser.Company.Address1;
            Address2= companyUser.Company.Address2;
            City= companyUser.Company.City;
            State = companyUser.Company.State;
            Zip= companyUser.Company.Zip;
           // Drivers = new List<DriverReturn>();
        }

        public long CompanyID { get; set; }
        public string Name { get; set; }
        public string PhoneNumber { get; set; }
        public string ContactName { get; set; }

        public string? Address1 { get; set; } = string.Empty;
        public string? Address2 { get; set; } = string.Empty;
        public string? City { get; set; } = string.Empty;
        public string? State { get; set; } = string.Empty;
        public string? Zip { get; set; } = string.Empty;
        public List<DriverReturn> Drivers { get; set; } = new List<DriverReturn>();

    }

}
