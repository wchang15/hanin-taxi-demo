using System.Globalization;

namespace KoreanTaxi
{
    public static class Constants
    {
        public static decimal MIM_TRIP_FEE = (decimal)6.0;
        public static decimal AMOUNT_PER_MILE = (decimal)2.0;
        public static double TRIP_MATCH_MILE_RANGE = 5;
        public static decimal TAX_PERCENTAGE = (decimal)6.65; // I don't know the correct amount
        public static decimal LARGE_TAXI_ADDER = (decimal)3.0;
        public static int DRIVER_MATCH_IDLE_TIME = 2; // Driver needs to wait atleast 2 seconds to be matched / re matched.

        public static string COMPANY = "company";
        public static string DRIVER = "driver";
        public static string CUSTOMER = "customer";

        /// <summary>
        /// Driver = when trip matched from background service
        /// Customer = when driver accepted the ride.
        /// </summary>
        public static string MATCH = "match"; 
        /// <summary>
        /// Customer = get driver location update
        /// </summary>
        public static string UPDATEDRIVERLOCATION = "updatedriverlocation";
        /// <summary>
        /// Customer = get notified that the trip started
        /// </summary>
        public static string TRIPSTART = "tripstart";
        /// <summary>
        /// Customer = get notified that the trip completed
        /// </summary>
        public static string TRIPCOMPLETE = "tripcomplete";
        /// <summary>
        /// Driver = get notified when customer canceled trip
        /// </summary>
        public static string CUSTOMERCANCEL = "customercancel";
        /// <summary>
        /// Customer = get notified when customer canceled trip
        /// </summary>
        public static string DRIVERCANCEL = "drivercancel";

        public static string COMPANYCANCEL = "companycancel";
        public static string PRICEUPDATE = "priceupdate";
        public static string NOTEUPDATE = "noteupdate";
        public static string COMPANYTRIP = "companytrip";
        public static string ALCOHOLDRIVERMATCH = "alcoholdrivermatch";

        public static CultureInfo USCULTURE = new CultureInfo("en-us");

        public static IApplicationBuilder UseSwaggerAuthorized(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<SwaggerBasicAuthMiddleware>();
        }
    }
}
