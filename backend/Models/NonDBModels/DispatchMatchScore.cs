namespace KoreanTaxi.Models.NonDBModels
{
    public class DispatchMatchScore
    {
        public bool IsEligible { get; set; }
        public double Score { get; set; }
        public double PickupDistanceMiles { get; set; }
        public int CustomerWaitMinutes { get; set; }
        public List<string> Reasons { get; set; } = new();
        public List<string> Rejections { get; set; } = new();
    }
}
