namespace KoreanTaxi.Models.NonDBModels
{
    public class DistanceToll
    {
        public decimal Distance { get; set; }
        public bool IsToll { get; set; } = false;

        public decimal Amount { get => Distance * Constants.AMOUNT_PER_MILE < Constants.MIM_TRIP_FEE ? Constants.MIM_TRIP_FEE : Distance * Constants.AMOUNT_PER_MILE;  }
    }
}
