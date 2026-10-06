using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Services;
using Xunit;

namespace HaninTaxi.Tests;

public class DispatchScoringTests
{
    private static readonly DateTime Now = new(2026, 10, 6, 12, 0, 0, DateTimeKind.Utc);
    private readonly DispatchScoringService scoring = new();

    private static (DriverQueue Driver, CustomerQueue Customer) Candidate()
    {
        var driver = new DriverQueue
        {
            Latitude = 40.8509,
            Longitude = -73.9701,
            Driver = new Driver
            {
                CompanyID = 10,
                IsAppTaxi = true,
                TLCApproved = true,
                Taxi = new Taxi { Size = EnumTaxiSize.SMALL },
                Company = new Company
                {
                    CompanyID = 10,
                    CompanyOperatingStates = new List<CompanyOperatingState>
                    {
                        new() { FromState = EnumState.NJ, ToState = EnumState.NY }
                    }
                }
            }
        };
        var customer = new CustomerQueue
        {
            CustomerQueueID = 20,
            CreatedDateTime = Now,
            Trip = new Trip
            {
                CalledTaxiSize = EnumTaxiSize.SMALL,
                PickupLocation = new GoogleLocation
                {
                    Latitude = 40.8509, Longitude = -73.9701,
                    State = EnumState.NJ, LocationType = EnumLocationType.OTHER
                },
                DropoffLocation = new GoogleLocation
                {
                    Latitude = 40.6413, Longitude = -73.7781,
                    State = EnumState.NY, LocationType = EnumLocationType.AIRPORT
                }
            }
        };
        return (driver, customer);
    }

    [Fact]
    public void Eligible_airport_candidate_has_explainable_score()
    {
        var (driver, customer) = Candidate();
        var result = scoring.ScoreCandidate(driver, customer, Now);
        Assert.True(result.IsEligible);
        Assert.Equal(65, result.Score);
        Assert.NotEmpty(result.Reasons);
        Assert.Empty(result.Rejections);
    }

    [Theory]
    [InlineData(EnumQueueStatus.PENDING)]
    [InlineData(EnumQueueStatus.ACCEPTED)]
    [InlineData(EnumQueueStatus.CUSTOMERCANCELED)]
    [InlineData(EnumQueueStatus.DRIVERCANCELED)]
    [InlineData(EnumQueueStatus.COMPANYCANCELED)]
    public void Non_waiting_customer_is_not_a_candidate(EnumQueueStatus status)
    {
        var (driver, customer) = Candidate();
        customer.QueueStatus = status;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Theory]
    [InlineData(EnumQueueStatus.PENDING)]
    [InlineData(EnumQueueStatus.ACCEPTED)]
    [InlineData(EnumQueueStatus.CUSTOMERCANCELED)]
    [InlineData(EnumQueueStatus.DRIVERCANCELED)]
    [InlineData(EnumQueueStatus.COMPANYCANCELED)]
    public void Non_waiting_driver_is_not_a_candidate(EnumQueueStatus status)
    {
        var (driver, customer) = Candidate();
        driver.QueueStatus = status;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Fact]
    public void Company_request_does_not_cross_company_boundary()
    {
        var (driver, customer) = Candidate();
        customer.CompanyID = 99;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Fact]
    public void Own_company_request_can_use_a_non_app_driver()
    {
        var (driver, customer) = Candidate();
        customer.CompanyID = driver.Driver!.CompanyID;
        driver.Driver.IsAppTaxi = false;
        Assert.True(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Fact]
    public void App_request_requires_an_app_enabled_driver()
    {
        var (driver, customer) = Candidate();
        driver.Driver!.IsAppTaxi = false;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Fact]
    public void Small_vehicle_cannot_take_a_large_vehicle_request()
    {
        var (driver, customer) = Candidate();
        customer.Trip!.CalledTaxiSize = EnumTaxiSize.LARGE;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Fact]
    public void Previously_rejected_request_is_not_offered_again()
    {
        var (driver, customer) = Candidate();
        driver.DriverQueueRejectedCustomerQueues!.Add(new DriverQueueRejectedCustomerQueue
        {
            CustomerQueueID = customer.CustomerQueueID
        });
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Fact]
    public void Airport_flag_constraint_is_enforced_for_app_rides()
    {
        var (driver, customer) = Candidate();
        driver.Driver!.TLCApproved = false;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Fact]
    public void Unconfigured_state_pair_is_rejected()
    {
        var (driver, customer) = Candidate();
        customer.Trip!.DropoffLocation!.State = EnumState.CT;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
    }

    [Theory]
    [InlineData(-10, 65)]
    [InlineData(5, 75)]
    [InlineData(50, 90)]
    public void Wait_bonus_is_nonnegative_and_capped(int minutes, double expected)
    {
        var (driver, customer) = Candidate();
        customer.CreatedDateTime = Now.AddMinutes(-minutes);
        Assert.Equal(expected, scoring.ScoreCandidate(driver, customer, Now).Score);
    }

    [Theory]
    [InlineData(1, 60)]
    [InlineData(10, 50)]
    public void Decline_penalty_is_capped(int declines, double expected)
    {
        var (driver, customer) = Candidate();
        driver.DeclinedCount = declines;
        Assert.Equal(expected, scoring.ScoreCandidate(driver, customer, Now).Score);
    }

    [Fact]
    public void Pickup_range_expands_with_customer_wait()
    {
        var (driver, customer) = Candidate();
        driver.Latitude += 0.15;
        Assert.False(scoring.ScoreCandidate(driver, customer, Now).IsEligible);
        Assert.True(scoring.ScoreCandidate(driver, customer, Now.AddMinutes(10)).IsEligible);
    }
}
