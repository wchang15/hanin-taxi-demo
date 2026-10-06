using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class Company
    {
        public Company()
        {
            Drivers = new HashSet<Driver>();
            CompanyOperatingStates = new HashSet<CompanyOperatingState>();
            CompanyQueues = new HashSet<CustomerQueue>();
        }

        public long CompanyID { get; set; }
        [MaxLength(255)]
        public string Name { get; set; }
        [MaxLength(50)]
        public string PhoneNumber { get; set; }
        [MaxLength(255)]
        public string ContactName { get; set; }
        [MaxLength(255)]
        public string? Address1 { get; set; } = string.Empty;
        [MaxLength(255)]
        public string? Address2 { get; set; } = string.Empty;
        [MaxLength(50)]
        public string? City { get; set; } = string.Empty;
        [MaxLength(50)]
        public string? State { get; set; } = string.Empty;
        [MaxLength(50)]
        public string? Zip { get; set; } = string.Empty;

        [Column(TypeName = "decimal(9,6)")]
        public double Longitude { get; set; }
        [Column(TypeName = "decimal(8,6)")]
        public double Latitude { get; set; }
        public EnumTimeZone TimeZone { get; set; } = EnumTimeZone.Eastern;  

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
        public DateTime? ModifiedDateTime { get; set; }

        public virtual ICollection<Driver>? Drivers { get; set; } = new HashSet<Driver>();
        public virtual ICollection<CompanyOperatingState>? CompanyOperatingStates { get; set; } = new HashSet<CompanyOperatingState>();
        public virtual ICollection<CustomerQueue>? CompanyQueues { get; set; } = new HashSet<CustomerQueue>();
        public virtual ICollection<CompanyUser>? CompanyUsers { get; set; } = new HashSet<CompanyUser>();
        public virtual ICollection<CompanyFrequentLocation>? CompanyFrequentLocations { get; set; } = new HashSet<CompanyFrequentLocation>();
        public virtual ICollection<CompanyCustomerPhoneNumber>? CompanyCustomerPhoneNumbers { get; set; } = new HashSet<CompanyCustomerPhoneNumber>();


    }
}
