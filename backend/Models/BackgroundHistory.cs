namespace KoreanTaxi.Models
{
    public class BackgroundHistory
    {

        public long BackgroundHistoryID { get; set; }
        public bool IsSuccess { get; set; }
        public int CustomerQueueCount { get; set; }
        public int DriverQueueCount { get; set; }
        public int SuccessAmount { get; set; }
        public int ErrorAmount { get; set; }
        public string Process { get; set; }
        public string Error { get; set; } = string.Empty;
        public DateTime CreatedDateTime { get; set; }

    }
}
