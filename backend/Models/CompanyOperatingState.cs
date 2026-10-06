using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CompanyOperatingState
    {
        public long CompanyOperatingStateID { get; set; }
        public long CompanyID { get; set; }
        public EnumState FromState { get; set; }
        public EnumState? ToState { get; set; }
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Company? Company { get; set; }
    }
}
