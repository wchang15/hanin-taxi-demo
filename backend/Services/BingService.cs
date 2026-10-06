using BingMapsRESTToolkit;
using BingMapsRESTToolkit.Extensions;
using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;

namespace KoreanTaxi.Services
{
    public class BingService : IBingService
    {

        private readonly IConfiguration configuration;
        private string BingMapKey;
        private readonly bool demoMode;


        public BingService(IConfiguration configuration)
        {
            this.configuration = configuration;
            BingMapKey = configuration["Routing:BingMapsKey"] ?? configuration["ConnectionStrings:bingString"] ?? string.Empty;
            demoMode = configuration.GetValue<bool>("DemoMode");
        }

        public async Task<DistanceToll?> GetRoute(GoogleLocation fromAddress, GoogleLocation toAddress)
        {
            if (demoMode || string.IsNullOrWhiteSpace(BingMapKey))
            {
                var distance = EstimateMiles(fromAddress.Latitude, fromAddress.Longitude, toAddress.Latitude, toAddress.Longitude);
                return await Task.FromResult(new DistanceToll { Distance = Math.Max(distance, 1), IsToll = false });
            }

            var request = new RouteRequest()
            {
                Waypoints = new List<SimpleWaypoint>()
                {
                    new SimpleWaypoint(new Coordinate(fromAddress.Latitude, fromAddress.Longitude)),
                    new SimpleWaypoint(new Coordinate(toAddress.Latitude, toAddress.Longitude))
                },
                WaypointOptimization = TspOptimizationType.TravelTime,
                RouteOptions = new BingMapsRESTToolkit.RouteOptions()
                {
                    TravelMode = TravelModeType.Driving,
                    DistanceUnits = DistanceUnitType.Miles,
                },
                BingMapsKey = BingMapKey
            };

            //Process the request by using the ServiceManager.
            var response = await request.Execute();

            if (response != null &&
                response.ResourceSets != null &&
                response.ResourceSets.Length > 0 &&
                response.ResourceSets[0].Resources != null &&
                response.ResourceSets[0].Resources.Length > 0)
            {

                var totalRoute = response.ResourceSets[0].Resources[0] as BingMapsRESTToolkit.Route;
                var routes = totalRoute.RouteLegs;

                if (routes != null && routes.Length > 0)
                {
                    var distanceToll = new DistanceToll();
                    distanceToll.Distance = (decimal)(totalRoute.TravelDistance / routes.Length);

                    foreach (var route in routes)
                    {
                        if (distanceToll.IsToll) break;
                        foreach (var item in route.ItineraryItems)
                        {
                            if (distanceToll.IsToll) break;
                            if (item.Warnings != null && item.Warnings.Length > 0)
                            {
                                foreach (var warning in item.Warnings)
                                {
                                    if (warning.WarningTypeEnum == WarningType.TollRoad)
                                    {
                                        distanceToll.IsToll = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    return distanceToll;
                }

            }
            return null;
        }

        private static decimal EstimateMiles(double fromLatitude, double fromLongitude, double toLatitude, double toLongitude)
        {
            const double earthRadiusMiles = 3958.8;
            static double ToRadians(double degrees) => degrees * Math.PI / 180;

            var latitudeDelta = ToRadians(toLatitude - fromLatitude);
            var longitudeDelta = ToRadians(toLongitude - fromLongitude);
            var fromLatRadians = ToRadians(fromLatitude);
            var toLatRadians = ToRadians(toLatitude);

            var a = Math.Sin(latitudeDelta / 2) * Math.Sin(latitudeDelta / 2) +
                    Math.Cos(fromLatRadians) * Math.Cos(toLatRadians) *
                    Math.Sin(longitudeDelta / 2) * Math.Sin(longitudeDelta / 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return (decimal)(earthRadiusMiles * c * 1.25);
        }
    }
}
