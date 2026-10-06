namespace KoreanTaxi.Models.NonDBModels
{
    public class DriverLocationReturn
    {

        public long DriverID { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string Name { get; set; } = string.Empty;
        public bool IsWorking { get; set; } = false;
        
    }
}
