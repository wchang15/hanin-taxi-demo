using KoreanTaxi.Models.Enums;

namespace KoreanTaxi.Models.NonDBModels
{
    public class RegisterRequest
    {
        public string Username { get; set; }
        public string Password { get; set; }
        public EnumUserRole Role { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }
        public EnumLanguage Language { get; set; }
        public List<bool> Terms { get; set; }
    }
}
