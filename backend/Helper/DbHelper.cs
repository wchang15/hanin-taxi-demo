using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using Stripe;
using System.ComponentModel;

namespace KoreanTaxi.Helper
{
    public static class DbHelper
    {

        public static string GetDescription(Enum value)
        {
            var field = value.GetType().GetField(value.ToString());
            var attr = field.GetCustomAttributes(typeof(DescriptionAttribute), false);
            return attr.Length == 0 ? value.ToString() : (attr[0] as DescriptionAttribute).Description;
        }

        public static decimal GetTaxedAmount(decimal amount, decimal tax)
        {
            return Math.Round(amount * ((tax + 100) / 100), 2);
        }

        public static TimeZoneInfo GetTimeZoneInfo(EnumTimeZone timezone)
        {
            var timezoneID = timezone.ToString() + " Standard Time";
            return TimeZoneInfo.FindSystemTimeZoneById(timezoneID);
        }

        public static DateTime TimeInTimeZone(DateTime utc, EnumTimeZone timeZone)
        {
            var timezoneInfo = GetTimeZoneInfo(timeZone);

            return TimeZoneInfo.ConvertTimeFromUtc(utc, timezoneInfo);
        }

        public static int GetDateInterval(DateTime date)
        {
            var diff = DateTime.UtcNow - date;
            double totalDays = diff.TotalDays;
            int days = (int)Math.Ceiling(totalDays);

            return days;
        }

    }
}


