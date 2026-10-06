namespace KoreanTaxi.Services
{
    public interface IEmailService
    {

        public void SendEmailToHanin(string title, string message);
        public void SendEmailToClient();
    }
}
