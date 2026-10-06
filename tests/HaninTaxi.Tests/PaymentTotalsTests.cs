using KoreanTaxi.Models;
using KoreanTaxi;
using System.Globalization;
using Xunit;

namespace HaninTaxi.Tests;

public class PaymentTotalsTests
{
    [Theory]
    [InlineData("44.0698267824976", "44.07")]
    [InlineData("44.065", "44.07")]
    [InlineData("44.064", "44.06")]
    public void Both_vehicle_quotes_are_rounded_before_confirmation(string mileage, string expected)
    {
        var trip = new Trip { MileageAmount = decimal.Parse(mileage, CultureInfo.InvariantCulture) };
        var fare = decimal.Parse(expected, CultureInfo.InvariantCulture);
        Assert.Equal(fare, trip.SmallTaxiFee);
        Assert.Equal(fare + Constants.LARGE_TAXI_ADDER, trip.LargeTaxiFee);
    }

    [Fact]
    public void Cash_fare_is_included_in_total_without_becoming_a_card_charge()
    {
        var payment = new Payment { CashAmount = 44.07m, TipAmount = 5m };
        Assert.Equal(49.07m, payment.FullAmount);
        Assert.Equal(0m, payment.CardAmount);
    }

    [Fact]
    public void Card_and_points_total_is_unchanged()
    {
        var payment = new Payment { CardAmount = 34.07m, PointAmount = 10m, TipAmount = 5m };
        Assert.Equal(49.07m, payment.FullAmount);
        Assert.Equal(0m, payment.CashAmount);
    }
}
