namespace KoreanTaxi.Services
{
    public interface ITwilioService
    {
        public Task<bool> ValidatePhoneNumber(string number);
        public Task<bool> SendSMS(string toNumber, string rand);
    }
}
