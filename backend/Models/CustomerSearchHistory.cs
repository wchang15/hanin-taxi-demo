using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CustomerSearchHistory
    {
        public long CustomerSearchHistoryID { get; set; }
        public long CustomerID { get; set; }
        public long GoogleLocationID { get; set; }

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Customer? Customer { get; set; }
        public virtual GoogleLocation? GoogleLocation { get; set; }
    }
}
