using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class ConfirmTripModel
    {
        public long TripID { get; set; }
        public long CustomerCardID { get; set; }
        public EnumTaxiSize EnumTaxiSize { get; set; }
        public EnumPaymentType EnumPaymentType { get; set; }
    }
}
