using System.ComponentModel.DataAnnotations;
using System.Diagnostics.Eventing.Reader;

namespace KoreanTaxi.Models.NonDBModels
{
    public class Report
    {
        public long DriverID { get; set; }
        public string FirstName { get; set; }
        public decimal TripAmount { get; set; }
        public decimal TipAmount { get; set; }
        public decimal TaxAmount { get; set; }
        public decimal Mileage { get; set; }
        public long TripCount { get; set; }
        public decimal TotalAmount { get; set; }
  
    }

}


