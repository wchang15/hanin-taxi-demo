using KoreanTaxi.Models;

namespace KoreanTaxi.Services
{
    public interface IGoogleService
    {
        public Task<List<GoogleLocation>> GetAutoComplete(string str);
    }
}
