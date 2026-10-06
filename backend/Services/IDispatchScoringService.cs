using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;

namespace KoreanTaxi.Services
{
    public interface IDispatchScoringService
    {
        DispatchMatchScore ScoreCandidate(DriverQueue driverQueue, CustomerQueue customerQueue, DateTime nowUtc);
    }
}
