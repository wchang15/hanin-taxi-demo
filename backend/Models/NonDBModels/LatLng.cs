namespace KoreanTaxi.Models.NonDBModels
{
    public class LatLng
    {
        public LatLng(double latitude, double longitude) {
            Latitude = latitude;
            Longitude = longitude;
        }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}
