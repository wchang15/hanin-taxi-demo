using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class Event
    {
        public long EventID { get; set; }
        public DateTime EventStartDate { get; set; }
        public DateTime EventEndDate { get; set; }
        [MaxLength(100)]
        public string EventName { get; set; } = string.Empty;
        [MaxLength(2000)]
        public string EventDescription { get; set; } = string.Empty;
    }
}
