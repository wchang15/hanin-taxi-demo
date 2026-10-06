using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;
using Newtonsoft.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace KoreanTaxi.Services
{
    public class TollService : ITollService
    {
        private readonly IConfiguration configuration;
        private readonly HttpClient httpClient;
        private string apiKey;
        private readonly bool demoMode;
        public TollService(IConfiguration configuration, HttpClient httpClient)
        {
            this.configuration = configuration;
            apiKey = configuration["TollGuru:ApiKey"] ?? configuration["ConnectionStrings:tollGuruToken"] ?? string.Empty;
            demoMode = configuration.GetValue<bool>("DemoMode");
            this.httpClient = httpClient;
        }

        public async Task<decimal> GetToll(GoogleLocation fromAddress, GoogleLocation toAddress)
        {
            return await GetToll(new LatLng(fromAddress.Latitude, fromAddress.Longitude), new LatLng(toAddress.Latitude, toAddress.Longitude));
        }

        public async Task<decimal> GetToll(LatLng from, LatLng to)
        {
            return await GetTollWaypoints(new List<LatLng> { from, to });
        }

        public async Task<decimal> GetTollWaypoints(List<LatLng> waypoints)
        {
            if (demoMode || string.IsNullOrWhiteSpace(apiKey)) return 0;

            var from = waypoints[0];
            var to = waypoints[1];
            var points = waypoints.Skip(2).Select(x => new { lat = x.Latitude, lng = x.Longitude }).ToList();
            var data = new
            {
                from = new { lat = from.Latitude, lng = from.Longitude },
                to = new { lat = to.Latitude, lng = to.Longitude },
                waypoints = points,
            };

            var body = JsonConvert.SerializeObject(data);
            var requestContent = new StringContent(body, Encoding.UTF8, "application/json");
            httpClient.DefaultRequestHeaders.Remove("x-api-key");
            httpClient.DefaultRequestHeaders.Add("x-api-key", apiKey);
            var response = await httpClient.PostAsync("", requestContent);

            var result = await response.Content.ReadAsStringAsync();

            var jsonObj = JsonConvert.DeserializeObject<dynamic>(result);

            try
            {
                return jsonObj.routes[0].costs.tag;
            }
            catch (Exception ex)
            {
                return 0;
            }
        }
    }
}
