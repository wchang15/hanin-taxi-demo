using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class TripReturnForDriver
    {

        public TripReturnForDriver(Trip trip) {
            TripID = trip.TripID;
            TripStatus= trip.TripStatus;
            TripType = trip.TripType;
            Note = trip.Notes ?? "";
            AlcoholPhoneNumber= trip.AlcoholPhoneNumber;
        }
        public long TripID { get; set; }
        public EnumTripStatus TripStatus { get; set; }
        public string StartPreferredName { get; set; } = string.Empty;
        public string StartName { get; set; }
        public string StartAddress { get; set; }
        public double StartLatitude { get; set; }
        public double StartLongitude { get; set; }
        public string EndPreferredName { get; set; } = string.Empty;
        public string EndName { get; set; }
        public string EndAddress { get; set; }
        public double EndLatitude { get; set; }
        public double EndLongitude { get; set; }
        public string CustomerFirstName { get; set; }
        public string CustomerPhoneNumber { get; set; }
        public string AlcoholPhoneNumber { get; set; } = string.Empty;
        public decimal TripAmount { get; set; }
        public EnumTripType TripType { get; set; }
        public EnumPaymentType PaymentType { get; set; } = EnumPaymentType.CARD;
        public string Note { get; set; }
    }
}
