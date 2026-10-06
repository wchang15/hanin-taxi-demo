using MailKit.Security;
using MimeKit.Text;
using MimeKit;
using Twilio.TwiML.Messaging;
using MailKit.Net.Smtp;

namespace KoreanTaxi.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration configuration;

        public EmailService(IConfiguration configuration)
        {
            this.configuration = configuration;
        }


        public void SendEmailToClient()
        {
            SendEmail("clientEmail@.com", "message", "title");
        }

        public void SendEmailToHanin(string title, string message)
        {
            SendEmail(configuration.GetValue<string>("Email:EmailUserName"), message, title);
        }

        private void SendEmail(string receiver, string message, string title)
        {
            var email = new MimeMessage();
            email.From.Add(MailboxAddress.Parse(receiver));
            email.To.Add(MailboxAddress.Parse(configuration.GetValue<string>("Email:EmailReceiver")));
            email.Subject = title;
            email.Body = new TextPart(TextFormat.Text) { Text = message };

            using var smtp = new SmtpClient();
            smtp.Connect(configuration.GetValue<string>("Email:EmailHost"), 587, SecureSocketOptions.StartTls);
            smtp.Authenticate(configuration.GetValue<string>("Email:EmailUserName"), configuration.GetValue<string>("Email:EmailPassword"));
            smtp.Send(email);
            smtp.Disconnect(true);
        }
    }
}
