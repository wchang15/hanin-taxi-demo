using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;

namespace KoreanTaxi.Services
{
    public interface IUserService
    {
        public long? GetUserID();
        public void CreatePasswordHash(string password, out byte[] passwordHash, out byte[] passwordSalt);
        public bool VerifyPasswordHash(string password, byte[] passwordHash, byte[] passwordSalt);
        public RefreshToken GenerateRefreshToken();
        public string CreateToken(LoginUser user);
    }
}
