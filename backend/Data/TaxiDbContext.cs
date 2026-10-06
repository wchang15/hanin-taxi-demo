using KoreanTaxi.Models;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Data
{
    public class TaxiDbContext : DbContext
    {
        public TaxiDbContext(DbContextOptions options) : base(options)
        {
        }

        public TaxiDbContext() { }
        // Logging History on Background services
        public virtual DbSet<BackgroundHistory> BackgroundHistories { get; set; }
        // Company Information
        public virtual DbSet<Company> Companies { get; set; }
        // Company Saved Customer Phone Number
        public virtual DbSet<CompanyCustomerPhoneNumber> CompanyCustomerPhoneNumbers { get; set; }
        // Company Saved Locations that shows up on the driver select dest screen (Driver)
        public virtual DbSet<CompanyFrequentLocation> CompanyFrequentLocations { get; set; }
        // Auto Complete with Korean preferred Name (Company and Driver)
        public virtual DbSet<CompanyGoogleLocation> CompanyGoogleLocations { get; set; }
        // Company Drivers can only get calls from these states (App Taxi)
        public virtual DbSet<CompanyOperatingState> CompanyOperatingStates { get; set; }
        // Preset trip price from one location to another :Specific for company (Call Taxi)
        public virtual DbSet<CompanyTripPrice> CompanyTripPrices { get; set; }
        // Company can have multiple users
        public virtual DbSet<CompanyUser> CompanyUsers { get; set; }
        // Customer Information
        public virtual DbSet<Customer> Customers { get; set; }
        // Customer Card Information
        public virtual DbSet<CustomerCard> CustomerCards { get; set; }
        // Customer and Company Queue : Waiting for driver to get matched
        public virtual DbSet<CustomerQueue> CustomerQueues { get; set; }
        // Customer saved location
        public virtual DbSet<CustomerSavedLocation> CustomerSavedLocations { get; set; }
        // Customer search history. Save last 5 searches
        public virtual DbSet<CustomerSearchHistory> CustomerSearchHistories { get; set; }
        // Coupon to add points to Customer (Customer)
        public virtual DbSet<Coupon> Coupons { get; set; }
        // Driver Information
        public virtual DbSet<Driver> Drivers { get; set; }
        // Driver Ratings from Customer (Not being used atm)
        public virtual DbSet<DriverRating> DriverRatings { get; set; }
        // Drivers waiting to get matched
        public virtual DbSet<DriverQueue> DriverQueues { get; set; }
        // Drivers rejected CustomerQueues. Driver does not get matched with rejected queue.
        public virtual DbSet<DriverQueueRejectedCustomerQueue> DriverQueueRejectedCustomerQueues { get; set; }
        // Events for Customer
        public virtual DbSet<Event> Events { get; set; }
        // Locations from Google Auto Complete
        public virtual DbSet<GoogleLocation> GoogleLocations { get; set; }
        // Login userID and pwd
        public virtual DbSet<LoginUser> LoginUsers { get; set; }
        // Payment information for Customer (Card payment)
        public virtual DbSet<Payment> Payments { get; set; }
        // Record of Point add from Customer
        public virtual DbSet<PointAddHistory> PointAddHistories { get; set; }
        // When calculating the toll fee, use the default location as driver's return point
        // StateDefaultLoc -> Pickup -> Dropoff -> StateDefaultLoc (App Taxi)
        public virtual DbSet<StateDefaultLocation> StateDefaultLocations { get; set; }
        // Additional State fees such as Tax, airport fee (App Taxi)
        public virtual DbSet<StateFee> StateFees { get; set; }
        // Taxi Car information
        public virtual DbSet<Taxi> Taxis { get; set; }
        // Trip information including findfare, completed, working etc.
        public virtual DbSet<Trip> Trips { get; set; }
        // Trip price detail information (App Taxi)
        public virtual DbSet<TripPriceDetail> TripPriceDetails { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            foreach (var relationship in modelBuilder.Model.GetEntityTypes().SelectMany(e => e.GetForeignKeys()))
            {
                relationship.DeleteBehavior = DeleteBehavior.Restrict;
            }

            modelBuilder.Entity<BackgroundHistory>(a =>
            {

            });

            modelBuilder.Entity<Company>(a =>
            {

            });

            modelBuilder.Entity<CompanyCustomerPhoneNumber>(a =>
            {
                a.HasIndex(x => x.CompanyID);
                a.HasIndex(x => x.CustomerName);
                a.HasIndex(x => x.GoogleLocationID);
            });

            modelBuilder.Entity<CompanyFrequentLocation>(a =>
            {
                a.HasIndex(x => x.CompanyID);
                a.HasIndex(x => x.GoogleLocationID);
            });

            modelBuilder.Entity<CompanyGoogleLocation>(a =>
            {
                a.HasIndex(x => x.GoogleLocationID).IsUnique();
                a.HasIndex(x => new { x.CompanyID, x.GoogleLocationID }).IsUnique();
            });

            modelBuilder.Entity<CompanyOperatingState>(a =>
            {
                a.HasIndex(x => x.CompanyID);
                a.HasIndex(x => x.FromState);
            });

            modelBuilder.Entity<CompanyTripPrice>(a =>
            {
                a.HasIndex(x => x.CompanyID);
            });

            modelBuilder.Entity<CompanyUser>(a =>
            {
                a.HasIndex(x => x.CompanyID);
                a.HasIndex(x => x.LoginUserID).IsUnique();
            });

            modelBuilder.Entity<Coupon>(a =>
            {
                a.HasIndex(x => x.Code).IsUnique();
                a.HasIndex(x => x.CustomerID);
            });

            modelBuilder.Entity<Customer>(a =>
            {
                a.HasIndex(x => x.LoginUserID).IsUnique();
                a.HasIndex(x => new { x.PhoneNumber, x.IsVerified }).HasFilter("IsVerified IS TRUE").IsUnique();
            });

            modelBuilder.Entity<CustomerCard>(a =>
            {
                a.HasIndex(x => x.CustomerID);
            });

            modelBuilder.Entity<CustomerQueue>(a =>
            {
                a.HasIndex(x => x.CreatedDateTime)
                .IsDescending();
                a.HasIndex(x => x.CustomerID)
                .HasFilter("CustomerID is not null")
                .IsUnique();
                a.HasIndex(x => x.CompanyID);
                a.HasIndex(x => x.QueueStatus);
            });

            modelBuilder.Entity<CustomerSavedLocation>(a =>
            {
                a.HasIndex(x => x.CustomerID);
                a.HasIndex(x => new { x.CustomerID, x.GoogleLocationID }).IsUnique();
                a.HasIndex(x => x.CreatedDateTime);
            });

            modelBuilder.Entity<CustomerSearchHistory>(a =>
            {
                a.HasIndex(x => x.CustomerID);
                a.HasIndex(x => new { x.CustomerID, x.GoogleLocationID }).IsUnique();
                a.HasIndex(x => x.CreatedDateTime);
            });

            modelBuilder.Entity<Driver>(a =>
            {
                a.HasIndex(x => x.LoginUserID).IsUnique();
                a.HasIndex(x => x.CompanyID);
                a.HasIndex(x => x.PhoneNumber);
            });

            modelBuilder.Entity<DriverQueue>(a =>
            {
                a.HasIndex(x => x.CreatedDateTime)
                .IsDescending();
                a.HasIndex(x => x.DriverID)
                .HasFilter("DriverID is not null")
                .IsUnique();
                a.HasIndex(x => x.QueueStatus);
                a.HasIndex(x => x.TripID);
                a.HasIndex(x => x.CustomerQueueID);
            });

            modelBuilder.Entity<DriverQueueRejectedCustomerQueue>(a =>
            {
                a.HasIndex(x => x.DriverQueueID);
            });

            modelBuilder.Entity<DriverRating>(a =>
            {
                a.HasIndex(x => x.DriverID);
                a.HasIndex(x => x.CustomerID);
            });

            modelBuilder.Entity<Event>(a =>
            {
                a.HasIndex(x => new { x.EventStartDate, x.EventEndDate }).IsUnique();
            });

            modelBuilder.Entity<GoogleLocation>(a =>
            {
                a.HasIndex(x => new { x.Name, x.Address }).IsUnique();
            });

            modelBuilder.Entity<LoginUser>(a =>
            {
                a.HasIndex(x => x.Username).IsUnique();
            });

            modelBuilder.Entity<Payment>(a =>
            {
                a.HasIndex(x => x.TripID).IsUnique();
                a.HasIndex(x => x.PaymentStatus);
                a.HasIndex(x => x.PaymentType);
            });

            modelBuilder.Entity<PointAddHistory>(a =>
            {
                a.HasIndex(x => x.CustomerID);
            });

            modelBuilder.Entity<StateDefaultLocation>(a =>
            {
                a.HasIndex(x => x.State).IsUnique();
            });

            modelBuilder.Entity<StateFee>(a =>
            {
                a.HasIndex(x => x.FromState);
                a.HasIndex(x => x.ToState);
            });

            modelBuilder.Entity<Taxi>(a =>
            {
                a.HasIndex(x => x.DriverID).IsUnique();
            });

            modelBuilder.Entity<Trip>(a =>
            {
                a.HasIndex(x => x.TripStatus);
                a.HasIndex(x => x.DriverID);
                a.HasIndex(x => x.CustomerID);
                a.HasIndex(x => x.CompanyID);
                a.HasIndex(x => x.CompletedTime);
                a.HasIndex(x => new { x.PickupLocationID, x.DropoffLocationID });
            });

            modelBuilder.Entity<TripPriceDetail>(a =>
            {
                a.HasIndex(x => x.TripID);
                a.HasIndex(x => x.StateFeeID);
            });



        }
    }
}
