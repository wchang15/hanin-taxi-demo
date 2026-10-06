using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class LoginRequest
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }
}
