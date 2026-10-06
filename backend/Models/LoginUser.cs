using KoreanTaxi.Models.Enums;
using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace KoreanTaxi.Models
{
    public class LoginUser
    {
        public LoginUser() { }
        public LoginUser(string username, byte[] passwordHash, byte[] passwordSalt, EnumUserRole role) {
            Username = username;
            PasswordHash = passwordHash;
            PasswordSalt = passwordSalt;
            Role = role;
        }
        public long LoginUserID { get; set; }
        [MaxLength(50)]
        public string Username { get; set; } = string.Empty;
        [MaxLength(50)]
        public string? Password { get; set; } // This is used to initially set the password.
        public byte[]? PasswordHash { get; set; }
        public byte[]? PasswordSalt { get; set; }
        [MaxLength(500)]
        public string? RefreshToken { get; set; }
        public DateTime? TokenCreated { get; set; }
        public DateTime? TokenExpires { get; set; }
        public EnumUserRole Role { get; set; } = EnumUserRole.CUSTOMER;
        public bool IsActive { get; set; } = true;


        public DateTime? LastLoginDateTime { get; set; }
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
        public DateTime? ModifiedDateTime { get; set; }
    }
}
