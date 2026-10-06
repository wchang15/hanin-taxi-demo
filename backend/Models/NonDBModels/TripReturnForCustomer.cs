using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class TripReturnForCustomer
    {

        public TripReturnForCustomer(Trip trip)
        {
            TripID = trip.TripID;
            TripStatus = trip.TripStatus;
            CalledTaxiSize = trip.CalledTaxiSize.Value;
            Amount = (trip.CalledTaxiSize == EnumTaxiSize.SMALL ? trip.SmallTaxiFee : trip.LargeTaxiFee).ToString("C", Constants.USCULTURE);
            SmallTaxiFee = trip.SmallTaxiFee.ToString("C", Constants.USCULTURE);
            LargeTaxiFee = trip.LargeTaxiFee.ToString("C", Constants.USCULTURE);
            CreatedDateTime= trip.CreatedDateTime;

        }

        public long TripID { get; set; }
        //public long DriverID { get; set; }
        public EnumTripStatus TripStatus { get; set; }
        public EnumTaxiSize CalledTaxiSize { get; set; }
        public EnumPaymentType EnumPaymentType { get; set; }
        public decimal PointUsed { get; set; }
        public string Amount { get; set; }
        public string SmallTaxiFee { get; set; }
        public string LargeTaxiFee { get; set; }
        public DateTime CreatedDateTime { get; set; }
        public string StartPreferredName { get; set; } = string.Empty;
        public string StartName { get; set; }
        public string StartAddress { get; set; }
        public double StartLatitude { get; set; }
        public double StartLongitude { get; set; }
        public EnumLocationType StartLocationType { get; set; }
        public string EndPreferredName { get; set; } = string.Empty;
        public string EndName { get; set; }
        public string EndAddress { get; set; }
        public double EndLatitude { get; set; }
        public double EndLongitude { get; set; }
        public EnumLocationType EndLocationType { get; set; }
        public long? CustomerCardID { get; set; }

    }
}
