using System.ComponentModel.DataAnnotations;

namespace KoreanTaxi.Models
{
    public class CompanyCustomerPhoneNumber
    {
        public long CompanyCustomerPhoneNumberID { get; set; }
        public long? GoogleLocationID { get; set; }
        [MaxLength(100)]
        public string CustomerName { get; set; } = string.Empty;
        public long CompanyID { get; set; }
        [MaxLength(50)]
        public string PhoneNumber { get; set; } = string.Empty;
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual GoogleLocation? GoogleLocation { get; set; }
        public virtual Company Company { get; set; }
    }
}
