using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class DriverQueue
    {
        public long DriverQueueID { get; set; }
        public long DriverID { get; set; }
        public EnumQueueStatus QueueStatus { get; set; } = EnumQueueStatus.WAITING;
        public int? DeclinedCount { get; set; } = 0;
        [Column(TypeName = "decimal(9,6)")]
        public double Longitude { get; set; }
        [Column(TypeName = "decimal(8,6)")]
        public double Latitude { get; set; }
        public long? TripID { get; set; }
        public long? CustomerQueueID { get; set; } //intentionally not fk.
        public DateTime DeclinedTime { get; set; } = DateTime.UtcNow;

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Driver? Driver { get; set; }
        public virtual Trip? Trip { get; set; }
        public virtual ICollection<DriverQueueRejectedCustomerQueue>? DriverQueueRejectedCustomerQueues { get; set; } = new HashSet<DriverQueueRejectedCustomerQueue>();
    }
}
