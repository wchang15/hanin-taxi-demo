//using KoreanTaxi.Migrations;
using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class CustomerReturn
    {

        public CustomerReturn(Customer customer) 
        {
            CustomerID = customer.CustomerID;
            FirstName= customer.FirstName;
            LastName= customer.LastName;
            Email= customer.Email;
            PhoneNumber= customer.PhoneNumber;
            CreatedDateTime= customer.CreatedDateTime;
            Fullname= customer.Fullname;
            IsVerified= customer.IsVerified;
            Point = customer.Point;
            DefaultCardID = 0;
            Language = customer.Language;
            SavedCards = new List<UserCard>();
            SearchHistories = new List<UserLocation>();
            SavedLocations = new List<UserLocation>();
        }

        public long CustomerID { get; set; }
        public string UserName { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public DateTime CreatedDateTime { get; set; }
        public string Fullname { get; set; }
        public bool IsVerified { get; set; }
        public decimal Point { get; set; }
        public long? DefaultCardID { get; set; }
        public EnumLanguage Language { get; set; }
        public List<UserCard>? SavedCards { get; set; }
        public List<UserLocation>? SearchHistories { get; set; }
        public List<UserLocation>? SavedLocations { get; set; }
    }

    public class UserCard
    {
        public UserCard(CustomerCard card)
        {
            CustomerCardID= card.CustomerCardID;
            Last4 = card.Last4;
            Brand = card.Brand;
            ExpirationMonth=card.ExpirationMonth; 
            ExpirationYear=card.ExpirationYear;
            IsDefault = card.Customer.DefaultCardID == card.CustomerCardID;

        }
        public long CustomerCardID { get; set; }
        public string? Last4 { get; set; }
        public string? Brand { get; set; }
        public int? ExpirationMonth { get; set; }
        public int? ExpirationYear { get; set; }
        public bool? IsDefault { get; set; }
    }

    public class UserLocation
    {
        public UserLocation(GoogleLocation loc)
        {
            PreferredName = loc.CompanyGoogleLocation?.Name ?? string.Empty;
            Address = loc.Address;
            Name= loc.Name;
            Latitude = loc.Latitude;
            Longitude = loc.Longitude;
            GoogleLocationID= loc.GoogleLocationID;
            LocationType = loc.LocationType;
        }

        public UserLocation(GoogleLocation loc, EnumSavedLocationType type)
        {
            PreferredName = loc.CompanyGoogleLocation?.Name ?? string.Empty;
            Address = loc.Address;
            Name = loc.Name;
            Latitude = loc.Latitude;
            Longitude = loc.Longitude;
            GoogleLocationID = loc.GoogleLocationID;
            Type = type;
            LocationType = loc.LocationType;
        }

        public long? GoogleLocationID { get; set; }
        public EnumSavedLocationType? Type { get; set; }
        public string PreferredName { get; set; } = string.Empty;
        public string? Address { get; set; }
        public string? Name { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public EnumLocationType LocationType { get; set; } = EnumLocationType.OTHER;
    }
}
