using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CustomerQueue
    {
        public CustomerQueue() { }
        public CustomerQueue(long? customerID, long? companyID,  long tripID) {
            CustomerID = customerID;
            CompanyID = companyID;
            TripID = tripID;
        }
        public long CustomerQueueID { get; set; }
        public long? CustomerID { get; set; }
        public long TripID { get; set; }
        public EnumQueueStatus QueueStatus { get; set; } = EnumQueueStatus.WAITING;
        public long? CompanyID { get; set; }
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Customer? Customer { get; set; }
        public virtual Company? Company { get; set; }
        public virtual Trip? Trip { get; set; }
    }
}
