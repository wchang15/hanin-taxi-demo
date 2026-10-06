using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class Driver
    {
        public Driver() { }
        public Driver(long loginUserID, string firstName, string lastName, string? email)
        {
            LoginUserID = loginUserID;
            FirstName = firstName;
            LastName = lastName;
            Email = email;
        }
        public long DriverID { get; set; }
        [MaxLength(255)]
        public string FirstName { get; set; }
        [MaxLength(255)]
        public string LastName { get; set; }
        public DateTime? DOB { get; set; }
        [MaxLength(255)]
        public string? Email { get; set; }
        [MaxLength(50)]
        public string PhoneNumber { get; set; }
        public long CompanyID { get; set; }
        public long LoginUserID { get; set; }
        public int DriverNumber { get; set; }
        public EnumLanguage Language { get; set; } = EnumLanguage.ENGLISH;
        public bool TLCApproved { get; set; } = false;
        public bool IsAppTaxi { get; set; } = false;
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
        public DateTime? IsArchived { get; set; }
        [MaxLength(25)]
        public string Map { get; set; } = String.Empty;
        public virtual Company? Company { get; set; }
        public virtual LoginUser? LoginUser { get; set; }
        public virtual Taxi? Taxi { get; set; } 
        public virtual ICollection<Trip>? Trips { get; set; } = new HashSet<Trip>();
        public virtual ICollection<DriverRating>? DriverRatings { get; set; } = new HashSet<DriverRating>();
        public virtual DriverQueue? DriverQueue { get; set; }
        [NotMapped]
        public string FullName { get => FirstName + " " + LastName; }
    }
}
