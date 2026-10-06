using KoreanTaxi.Models.Enums;
using Stripe;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Data.SqlTypes;

namespace KoreanTaxi.Models
{
    public class Customer
    {
        public Customer() { }
        public Customer(long loginUserID, string firstName, string lastName, string? email, EnumLanguage language, List<bool> terms)
        {
            LoginUserID = loginUserID;
            FirstName = firstName;
            LastName = lastName;
            Email = email;
            Language = language;
            Term1 = terms[0];
            Term2 = terms[1];
        }
        public long CustomerID { get; set; }
        [MaxLength(255)]
        public string FirstName { get; set; }
        [MaxLength(255)]
        public string LastName { get; set; }
        [MaxLength(255)]
        public string? Email { get; set; }
        [MaxLength(50)]
        public string? PhoneNumber { get; set; }
        public long LoginUserID { get; set; }
        [MaxLength(255)]
        public string? StripeCustomerID { get; set; }
        public bool IsVerified { get; set; } = false;
        [MaxLength(50)]
        public string? AuthNumber { get; set; }
        public decimal Point { get; set; } = 0;
        public EnumLanguage Language { get; set; } = EnumLanguage.ENGLISH;
        public bool Term1 { get; set; } = false;
        public bool Term2 { get; set; } = false;
        public long? DefaultCardID { get; set; }
        public EnumTimeZone TimeZone { get; set; } = EnumTimeZone.Eastern;

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual LoginUser? LoginUser { get; set; }
        public virtual ICollection<CustomerCard>? CustomerCards { get; set; } = new HashSet<CustomerCard>();
        public virtual ICollection<Trip>? Trips { get; set; } = new HashSet<Trip>();
        public virtual CustomerQueue? CustomerQueue { get; set; }
        public virtual ICollection<CustomerSavedLocation>? CustomerSavedLocations { get; set; } = new HashSet<CustomerSavedLocation>();
        public virtual ICollection<CustomerSearchHistory>? CustomerSearchHistories { get; set; } = new HashSet<CustomerSearchHistory>();

        [NotMapped]
        public string Fullname { get => FirstName + " " + LastName;}

    }
}
