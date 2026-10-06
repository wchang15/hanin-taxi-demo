using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class DriverQueueRejectedCustomerQueue
    {
        public long DriverQueueRejectedCustomerQueueID { get; set; }
        public long DriverQueueID { get; set; }
        public long CustomerQueueID { get; set; } //Intentionally left as non fk.

        public virtual DriverQueue? DriverQueue { get; set; }
    }
}
