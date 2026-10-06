namespace KoreanTaxi.Models.NonDBModels
{
    public class EmailRequest
    {
        public long? TripID { get; set; }
        public string Message { get; set; }
        public string Screen { get; set; }
    }
}
