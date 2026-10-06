namespace KoreanTaxi.Models.NonDBModels
{
    public class PhoneNumberRequest
    {
        public string? PhoneNumber { get; set; }
        public string? OTP { get; set; }
        public bool IsVerified { get; set; } = false;

    }
}
