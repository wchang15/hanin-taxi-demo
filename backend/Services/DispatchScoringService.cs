using Geolocation;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;

namespace KoreanTaxi.Services
{
    public class DispatchScoringService : IDispatchScoringService
    {
        public DispatchMatchScore ScoreCandidate(DriverQueue driverQueue, CustomerQueue customerQueue, DateTime nowUtc)
        {
            var result = new DispatchMatchScore();
            var trip = customerQueue.Trip;
            var driver = driverQueue.Driver;
            var pickup = trip?.PickupLocation;
            var dropoff = trip?.DropoffLocation;

            if (trip == null || driver == null || driver.Taxi == null || pickup == null)
            {
                result.Rejections.Add("Missing trip, driver, taxi, or pickup data.");
                return result;
            }

            if (driverQueue.QueueStatus != EnumQueueStatus.WAITING || customerQueue.QueueStatus != EnumQueueStatus.WAITING)
            {
                result.Rejections.Add("Both driver and customer queues must be waiting.");
                return result;
            }

            if (customerQueue.CompanyID.HasValue && customerQueue.CompanyID.Value != driver.CompanyID)
            {
                result.Rejections.Add("Company request belongs to a different driver company.");
                return result;
            }

            if (trip.CalledTaxiSize.HasValue && driver.Taxi.Size < trip.CalledTaxiSize.Value)
            {
                result.Rejections.Add("Vehicle size is smaller than requested.");
                return result;
            }

            if (driverQueue.DriverQueueRejectedCustomerQueues?.Any(x => x.CustomerQueueID == customerQueue.CustomerQueueID) == true)
            {
                result.Rejections.Add("Driver previously rejected this request.");
                return result;
            }

            if (customerQueue.CompanyID == null)
            {
                if (!driver.IsAppTaxi)
                {
                    result.Rejections.Add("Driver is not enabled for app-originated rides.");
                    return result;
                }

                if (dropoff != null && driver.Company?.CompanyOperatingStates?.Any(x =>
                    x.FromState == pickup.State && (x.ToState == null || x.ToState == dropoff.State)) != true)
                {
                    result.Rejections.Add("Driver company is not configured for this pickup/dropoff state pair.");
                    return result;
                }

                var isNewYorkAirportRide =
                    (pickup.LocationType == EnumLocationType.AIRPORT && (pickup.State == EnumState.NY || pickup.State == EnumState.NYC)) ||
                    (dropoff?.LocationType == EnumLocationType.AIRPORT && (dropoff.State == EnumState.NY || dropoff.State == EnumState.NYC));

                if (isNewYorkAirportRide && !driver.TLCApproved)
                {
                    result.Rejections.Add("New York airport rides require TLC approval.");
                    return result;
                }
            }

            result.PickupDistanceMiles = GeoCalculator.GetDistance(
                driverQueue.Latitude,
                driverQueue.Longitude,
                pickup.Latitude,
                pickup.Longitude);

            result.CustomerWaitMinutes = Math.Max(0, (int)(nowUtc - customerQueue.CreatedDateTime).TotalMinutes);
            var matchRangeMiles = Constants.TRIP_MATCH_MILE_RANGE + result.CustomerWaitMinutes;

            if (customerQueue.CompanyID == null && result.PickupDistanceMiles > matchRangeMiles)
            {
                result.Rejections.Add("Driver is outside the current pickup range.");
                return result;
            }

            result.IsEligible = true;
            result.Score = CalculateScore(result, driverQueue, customerQueue);
            result.Reasons.Add($"Pickup distance: {result.PickupDistanceMiles:0.0} miles.");
            result.Reasons.Add($"Customer wait time: {result.CustomerWaitMinutes} minutes.");
            result.Reasons.Add("Vehicle size and operating constraints are satisfied.");

            if (pickup.LocationType == EnumLocationType.AIRPORT || dropoff?.LocationType == EnumLocationType.AIRPORT)
            {
                result.Reasons.Add("Airport ride constraint evaluated.");
            }

            return result;
        }

        private static double CalculateScore(DispatchMatchScore score, DriverQueue driverQueue, CustomerQueue customerQueue)
        {
            var distanceScore = Math.Max(0, 60 - (score.PickupDistanceMiles * 8));
            var waitScore = Math.Min(25, score.CustomerWaitMinutes * 2);
            var declinePenalty = Math.Min(15, (driverQueue.DeclinedCount ?? 0) * 5);
            var airportBoost = customerQueue.Trip?.PickupLocation?.LocationType == EnumLocationType.AIRPORT ||
                               customerQueue.Trip?.DropoffLocation?.LocationType == EnumLocationType.AIRPORT
                ? 5
                : 0;

            return Math.Round(distanceScore + waitScore + airportBoost - declinePenalty, 2);
        }
    }
}
