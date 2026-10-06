using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class Payment
    {
        public long PaymentID { get; set; }
        public decimal CardAmount { get; set; }
        public decimal CashAmount { get; set; }
        public decimal TipAmount { get; set; } = 0;
        public EnumPaymentStatus PaymentStatus { get; set; } = EnumPaymentStatus.PENDING;
        [MaxLength(255)]
        public string? PaymentIntentID { get; set; }
        public EnumPaymentType PaymentType { get; set; } = EnumPaymentType.POINTCARD;
        public decimal PointAmount { get; set; }
        public long TripID { get; set; }
        public long? CustomerCardID { get; set; }

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
        public virtual Trip? Trip { get; set; }
        public virtual CustomerCard? CustomerCard { get; set; }


        [NotMapped]
        public decimal FullAmount { get => CardAmount + CashAmount + PointAmount + TipAmount; }

    }
}
