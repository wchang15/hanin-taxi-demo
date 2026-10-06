using KoreanTaxi.Helper;
using KoreanTaxi.Models.Enums;
using Stripe;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Drawing;

namespace KoreanTaxi.Models
{
    public class Trip
    {
        public Trip() { }
        public Trip(long? customerID, long? companyID, long pickupLocationID, long? dropoffLocationID)
        {
            CustomerID = customerID;
            CompanyID= companyID;
            PickupLocationID = pickupLocationID;
            DropoffLocationID = dropoffLocationID;
            TripStatus = EnumTripStatus.CUSTOMERSEARCHING;
        }

        public long TripID { get; set; }
        public long? CustomerID { get; set; }
        public long? CompanyID { get; set; }
        public long? DriverID { get; set; }
        public EnumTripStatus TripStatus { get; set; } = EnumTripStatus.CUSTOMERSEARCHING;

        public long PickupLocationID { get; set; }
        public long? DropoffLocationID { get; set; }

        public EnumTaxiSize? CalledTaxiSize { get; set; }
        public decimal Mileage { get; set; } // ex) 4.5 miles to dest
        public decimal MileageAmount { get; set; } // ex) $9 for trip
        public decimal TollAmount { get; set; } = 0;
        public decimal SmallStateFeeAmount { get; set; } = 0;
        public decimal LargeStateFeeAmount { get; set; } = 0;
        [MaxLength(50)]
        public string CustomerPhoneNumber { get; set; } = string.Empty; // This field is for company
        [MaxLength(50)]
        public string AlcoholPhoneNumber { get; set; } = string.Empty;
        public long? AlcoholTripID { get; set; }
        public decimal CompanyTripAmount { get; set; } = 0; // This field is for company
        [MaxLength(500)]
        public string? Notes { get; set; }

        public EnumTripType TripType { get; set; } = EnumTripType.CARD;

        [NotMapped]
        public decimal SmallTaxiFee { get => decimal.Round(MileageAmount + TollAmount + SmallStateFeeAmount, 2, MidpointRounding.AwayFromZero); }
        [NotMapped]
        public decimal LargeTaxiFee { get => decimal.Round(MileageAmount + Constants.LARGE_TAXI_ADDER + TollAmount + LargeStateFeeAmount, 2, MidpointRounding.AwayFromZero); }


        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
        public DateTime? CompletedTime { get; set; }

        public virtual Customer? Customer { get; set; }
        public virtual Driver? Driver { get; set; }
        public virtual GoogleLocation? PickupLocation { get; set; }
        public virtual GoogleLocation? DropoffLocation { get; set; }
        public virtual Payment? Payment { get; set; }
        public virtual CustomerQueue? CustomerQueue { get; set; }
        public virtual Company? Company { get; set; }
    }
}
