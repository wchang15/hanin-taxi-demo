using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;
using Microsoft.EntityFrameworkCore;
using Stripe;
using System.Security.Cryptography;
using Twilio;
using Twilio.Clients;
using Twilio.Exceptions;
using Twilio.Rest.Api.V2010.Account;
using Twilio.Rest.Lookups.V2;
using Twilio.Rest.Trunking.V1;
using Twilio.TwiML.Voice;
using Twilio.Types;

namespace KoreanTaxi.Services
{
    public class TwilioService : ITwilioService
    {

        private readonly IConfiguration configuration;
        private readonly string accountSid;
        private readonly string authToken;
        private readonly string apiKeySid;
        private readonly string apiKeySecret;
        private readonly string fromNumber;
        private readonly bool demoMode;
        public TwilioService(IConfiguration configuration)
        {
            this.configuration = configuration;
            demoMode = configuration.GetValue<bool>("DemoMode");
            accountSid = configuration["Twilio:AccountSid"] ?? configuration["ConnectionStrings:twilioAccountSID"] ?? string.Empty;
            authToken = configuration["Twilio:AuthToken"] ?? configuration["ConnectionStrings:twilioAuthToken"] ?? string.Empty;
            apiKeySid = configuration["Twilio:ApiKeySid"] ?? string.Empty;
            apiKeySecret = configuration["Twilio:ApiKeySecret"] ?? string.Empty;
            fromNumber = configuration["Twilio:FromNumber"] ?? string.Empty;
            if (!demoMode && !string.IsNullOrWhiteSpace(accountSid))
            {
                if (!string.IsNullOrWhiteSpace(apiKeySid) && !string.IsNullOrWhiteSpace(apiKeySecret))
                {
                    TwilioClient.Init(apiKeySid, apiKeySecret, accountSid);
                }
                else if (!string.IsNullOrWhiteSpace(authToken))
                {
                    TwilioClient.Init(accountSid, authToken);
                }
            }

        }

        public async Task<bool> ValidatePhoneNumber(string number)
        {
            if (demoMode) return await System.Threading.Tasks.Task.FromResult(true);

            number = PhoneNumberFormat(number);
            try
            {
                var numberDetails = await PhoneNumberResource.FetchAsync(pathPhoneNumber: number);

                return numberDetails.Valid ?? false;
            }
            catch (Exception ex)
            {
            }
            return false;
        }

        public async Task<bool> SendSMS(string toNumber, string rand)
        {
            if (demoMode) return await System.Threading.Tasks.Task.FromResult(true);
            if (string.IsNullOrWhiteSpace(fromNumber))
            {
                throw new InvalidOperationException("Twilio:FromNumber is not configured.");
            }

            toNumber = PhoneNumberFormat(toNumber);
            string message = $"Enter Activation Code: {rand} for Hanin Taxi mobile application.";
            try
            {
                await MessageResource.CreateAsync(to: new PhoneNumber(toNumber), from: new PhoneNumber(fromNumber), body: message);
            }
            catch (Exception ex)
            {
                return false;
            }
            return true;
        }

        private string PhoneNumberFormat(string number)
        {
            return $"+1{number.Replace("-", string.Empty)}";
        }


    }
}
