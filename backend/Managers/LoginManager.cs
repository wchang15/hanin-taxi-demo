using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace KoreanTaxi.Managers
{
    public class LoginManager
    {
        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;

        public LoginManager(TaxiDbContext ctx, IUserService userService)
        {
            this.ctx = ctx;
            this.userService = userService;
        }

        public async Task<LoginUser?> GetCompanyUser(string name)
        {
            var companyUser = await ctx.LoginUsers.Where(x => x.Username == name && x.Role == EnumUserRole.COMPANY && x.IsActive).FirstOrDefaultAsync();
            return companyUser;
        }

        public async Task<LoginUser?> GetDriverUser(string name)
        {
            var driverUser = await ctx.LoginUsers.Where(x => x.Username == name && x.Role == EnumUserRole.DRIVER && x.IsActive).FirstOrDefaultAsync();
            return driverUser;
        }

        public async Task<LoginUser?> GetCustomerUser(string name)
        {
            var customerUser = await ctx.LoginUsers.Where(x => x.Username == name && x.Role == EnumUserRole.CUSTOMER && x.IsActive).FirstOrDefaultAsync();
            return customerUser;
        }

        public async Task<LoginUser?> GetLoginUser(long userID)
        {
            var user = await ctx.LoginUsers.Where(x => x.LoginUserID == userID && x.IsActive).FirstOrDefaultAsync();
            return user;
        }

        public async Task<LoginUser?> GetLoginUserByRefreshToken(string refreshToken)
        {
            var user = await ctx.LoginUsers.Where(x => x.RefreshToken == refreshToken && x.IsActive).FirstOrDefaultAsync();
            return user;
        }

        public async Task<string?> FindCustomerUsername(string otp, string phoneNumber)
        {
            var customer = await ctx.Customers.Include(x => x.LoginUser).Where(x => x.AuthNumber == otp && x.PhoneNumber == phoneNumber && x.LoginUser.IsActive).FirstOrDefaultAsync();
            if (customer != null)
            {
                customer.AuthNumber = null;
                ctx.SaveChanges();
                return customer.LoginUser.Username;
            }
            return null;
        }

        public async Task<bool> LogoutUser(LoginUser user)
        {
            user.RefreshToken = null;
            user.TokenCreated = null;
            user.TokenExpires = null;
            await ctx.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteUser(LoginUser user)
        {
            user.IsActive = false;
            await ctx.SaveChangesAsync();
            return true;
        }


        public async Task<LoginUser> RegisterLoginUser(RegisterRequest request)
        {
            userService.CreatePasswordHash(request.Password, out byte[] passwordHash, out byte[] passwordSalt);
            var user = new LoginUser(request.Username, passwordHash, passwordSalt, request.Role);
            ctx.LoginUsers.Add(user);
            await ctx.SaveChangesAsync();
            return user;
        }

        public async Task UpdatePassword(string password, LoginUser loginuser)
        {
            userService.CreatePasswordHash(password, out byte[] passwordHash, out byte[] passwordSalt);
            loginuser.PasswordHash = passwordHash;
            loginuser.PasswordSalt = passwordSalt;
            await ctx.SaveChangesAsync();
        }
    }
}
