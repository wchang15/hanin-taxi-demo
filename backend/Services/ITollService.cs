using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;

namespace KoreanTaxi.Services
{
    public interface ITollService
    {
        public Task<decimal> GetToll(GoogleLocation fromAddress, GoogleLocation toAddress);
        public Task<decimal> GetToll(LatLng from, LatLng to);
        /// <summary>
        /// Get toll for whole trip
        /// </summary>
        /// <param name="waypoints">item 0 = start, item 1 = end, rest are waypoints</param>
        /// <returns></returns>
        public Task<decimal> GetTollWaypoints(List<LatLng> waypoints);


    }
}
