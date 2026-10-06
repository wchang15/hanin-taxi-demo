using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class PointAddHistory
    {
        public long PointAddHistoryID { get; set; }
        public EnumPointType PointType { get; set; }
        public decimal Amount { get; set; }
        public long CustomerID { get; set; }
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Customer? Customer { get; set; }
    }
}
