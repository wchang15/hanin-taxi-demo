using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;

namespace KoreanTaxi.Services
{
    public interface IBingService
    {
        public Task<DistanceToll?> GetRoute(GoogleLocation fromAddress, GoogleLocation toAddress);
    }
}
