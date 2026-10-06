using KoreanTaxi.Models.Enums;
using Org.BouncyCastle.Security;
using System.ComponentModel.DataAnnotations;
using System.Net.NetworkInformation;

namespace KoreanTaxi.Models.NonDBModels
{
    public class TripReturnForCompany
    {
        //public TripReturnForCompany(Trip trip)
        //{
        //    TripID = trip.TripID;
        //    TripStatus = trip.TripStatus;
        //    CreatedDateTime = trip.CreatedDateTime;
        //    StartName = trip.PickupLocation.Name;
        //    StartAddress = trip.PickupLocation.Address;
        //    StartLatitude = trip.PickupLocation.Latitude;
        //    StartLongitude = trip.PickupLocation.Longitude;
        //    //EndName = trip.DropoffLocation.Name;
        //    //EndAddress = trip.DropoffLocation.Address;
        //    //EndLatitude = trip.DropoffLocation.Latitude;
        //    //EndLongitude = trip.DropoffLocation.Longitude;

        //    //DriverNumber = trip.Driver.DriverNumber;
        //    //DriverPhoneNumber = trip.Driver.PhoneNumber;
        //    //Color = trip.Driver.Taxi.Color;
        //    //Make = trip.Driver.Taxi.Make;
        //    //Model = trip.Driver.Taxi.Model;
        //    //LicensePlate = trip.Driver.Taxi.LicensePlate;

        //    StartLocationType = trip.PickupLocation.LocationType;
        //    PhoneNumber = trip.CustomerPhoneNumber;
        //    Notes = trip.Notes;
        //    CompanyTripPrice = trip.CompanyTripAmount;
        //}
        public long TripID { get; set; }
        public EnumTripStatus TripStatus { get; set; }
        public DateTime CreatedDateTime { get; set; }
        // start locations
        public long StartLocationId { get; set; }
        public string StartPreferredName { get; set; } = string.Empty;
        public string StartName { get; set; }
        public decimal CompanyTripPrice { get; set; }
        public string StartAddress { get; set; }
        public double StartLatitude { get; set; }
        public double StartLongitude { get; set; }
        public EnumLocationType StartLocationType { get; set; }
        // end locations
        public long? EndLocationId { get; set; }
        public string EndPreferredName { get; set; } = string.Empty;
        public string? EndName { get; set; }
        public string? EndAddress { get; set; }
        public double? EndLatitude { get; set; }
        public double? EndLongitude { get; set; }
        public EnumLocationType EndLocationType { get; set; }
        // drivers
        public long? DriverId { get; set; }
        public int? DriverNumber { get; set; }
        public string? DriverPhoneNumber { get; set; }
        // Taxi
        public EnumTaxiColor? Color { get; set; }
        public EnumTaxiMake? Make { get; set; }
        public string? Model { get; set; }
        public string? LicensePlate { get; set; }
        // Company
        // ...
        // extras
        public string? PhoneNumber { get; set; }
        public string? Notes { get; set; }
  


    }
}
