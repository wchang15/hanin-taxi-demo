using KoreanTaxi.Data;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LoginController : ControllerBase
    {
        private readonly IUserService userService;
        private readonly LoginManager loginManager;
        private readonly CustomerManager customerManager;
        private readonly DriverManager driverManager;
        private readonly CompanyManager companyManager;
        private readonly TaxiDbContext ctx;


        public LoginController(TaxiDbContext ctx, IUserService userService, LoginManager loginManager, CustomerManager customerManager, DriverManager driverManager, CompanyManager companyManager)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.loginManager = loginManager;
            this.customerManager = customerManager;
            this.driverManager = driverManager;
            this.companyManager = companyManager;
        }

        [HttpPost("RegisterCustomer")]
        public async Task<IActionResult> RegisterCustomer(RegisterRequest request)
        {
            // phone number check
            var isDupUserName = ctx.LoginUsers.Where(x => x.Username == request.Username).Count();
            if (isDupUserName > 0) return BadRequest("Login ID Exist");

            var isDupPhoneNumber = ctx.Customers.Where(x => x.PhoneNumber == request.PhoneNumber && x.IsVerified).Count();
            if (isDupPhoneNumber > 0) return BadRequest("Phone Number Exist");

            var user = await loginManager.RegisterLoginUser(request);
            if (user == null) return BadRequest("User not created");

            var customer = await customerManager.RegisterCustomer(request, user.LoginUserID);
            if (customer == null) return BadRequest("Customer not created");    

            var stripeCustomerID = await customerManager.AddStripeCustomer(customer);
            if (stripeCustomerID == null) return BadRequest("Stripe Account not created");

            string token = await CreateTokens(user);

            var authSuccess = await customerManager.SendAuthNumber(customer);

            var retObj = new
            {
                customer = await customerManager.CustomerReturn(customer),
                token,
            };

            return Ok(retObj);
        }

        [HttpPost("LoginCompany")]
        public async Task<ActionResult<string>> LoginCompany(LoginRequest request)
        {
            var user = await loginManager.GetCompanyUser(request.Username);
            if (user == null) return NotFound("User Not Found.");
            if (!user.IsActive) return BadRequest("Removed User.");

            if (user.Password == null)
            {
                var verifyPassword = userService.VerifyPasswordHash(request.Password, user.PasswordHash, user.PasswordSalt);
                if (!verifyPassword) return BadRequest("Wrong password.");
            }
            else
            {
                if (request.Password != user.Password) return BadRequest("Wrong password");
            }

            string token = await CreateTokens(user);

            var company = await companyManager.GetCompanyByLoginUserID(user.LoginUserID).FirstOrDefaultAsync();
            if (company == null) return NotFound("Company account not found");
    
            var retObj = new
            {
                company = await companyManager.CompanyReturn(company.CompanyID, user.LoginUserID),
                token,
                user.RefreshToken,
            };

            return Ok(retObj);
        }

        [HttpPost("LoginDriver")]
        public async Task<ActionResult<string>> LoginDriver(LoginRequest request)
        {
            var user = await loginManager.GetDriverUser(request.Username);
            if (user == null) return NotFound("User Not Found.");
            if (!user.IsActive) return BadRequest("Removed User.");

            if (user.Password == null)
            {
                var verifyPassword = userService.VerifyPasswordHash(request.Password, user.PasswordHash, user.PasswordSalt);
                if (!verifyPassword) return BadRequest("Wrong password.");
            }
            else
            {
                if (request.Password != user.Password) return BadRequest("Wrong password");
            }

            string token = await CreateTokens(user);

            var driver = await driverManager.GetDriverByLoginUserID(user.LoginUserID);
            if (driver == null) return NotFound("Driver account not found");
            if (driver.IsArchived != null) return NotFound("Archived Driver");

            var retObj = new
            {
                driver = await driverManager.DriverReturn(driver.DriverID), 
                token 
            };
            
            return Ok(retObj);
        }

        [HttpPost("LoginCustomer")]
        public async Task<IActionResult> LoginCustomer(LoginRequest request)
        {
            var user = await loginManager.GetCustomerUser(request.Username);
            if (user == null) return NotFound("User Not Found.");
            if (!user.IsActive) return BadRequest("Removed User.");

            if (user.Password == null) 
            {
                var verifyPassword = userService.VerifyPasswordHash(request.Password, user.PasswordHash, user.PasswordSalt);
                if (!verifyPassword) return BadRequest("Wrong password.");
            }
            else
            {
                if (request.Password != user.Password) return BadRequest("Wrong password");
            }

            string token = await CreateTokens(user);

            var customer = await customerManager.GetCustomerByLoginUserID(user.LoginUserID).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer Not Found.");

            if (!customer.IsVerified) await customerManager.SendAuthNumber(customer);

            var retObj = new
            {
                customer = await customerManager.CustomerReturn(customer),
                token
            };

            return Ok(retObj);
        }

        [HttpGet("Logout"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER) + ", " + nameof(EnumUserRole.DRIVER) + ", " + nameof(EnumUserRole.COMPANY))]
        public async Task<ActionResult<string>> Logout()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var user = await loginManager.GetLoginUser(userID.Value);
            if (user == null) return NotFound("User Not Found.");

            Response.Cookies.Delete("refreshToken");
            await loginManager.LogoutUser(user);

            return Ok(user);
        }

        [HttpDelete("Delete"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER) + ", " + nameof(EnumUserRole.DRIVER) + ", " + nameof(EnumUserRole.COMPANY))]
        public async Task<ActionResult<string>> Delete()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");

            var user = await loginManager.GetLoginUser(userID.Value);
            if (user == null) return NotFound("User Not Found.");

            Response.Cookies.Delete("refreshToken");
            await loginManager.DeleteUser(user);

            userService.CreateToken(user);

            return Ok("Success");
        }

        [HttpPost("RefreshTokenCustomer")]
        public async Task<ActionResult<string>> RefreshTokenCustomer()
        {
            var refreshToken = Request.Cookies["refreshToken"];
            if (refreshToken == null) return BadRequest("Token not received");

            var user = await loginManager.GetLoginUserByRefreshToken(refreshToken);
            if (user == null) return NotFound("Token not found");

            if (user.TokenExpires < DateTime.UtcNow)
            {
                return Unauthorized("Token expired");
            }

            string token = await CreateTokens(user);

            var customer = await customerManager.GetCustomerByLoginUserID(user.LoginUserID).FirstOrDefaultAsync();
            if (customer == null) return NotFound("Customer account not found");

            if (!customer.IsVerified) await customerManager.SendAuthNumber(customer);

            var retObj = new
            {
                customer = await customerManager.CustomerReturn(customer),
                token,
            };

            return Ok(retObj);
        }

        [HttpPost("RefreshTokenDriver")]
        public async Task<ActionResult<string>> RefreshTokenDriver()
        {
            var refreshToken = Request.Cookies["refreshToken"];
            if (refreshToken == null) return BadRequest("Token not received");

            var user = await loginManager.GetLoginUserByRefreshToken(refreshToken);
            if (user == null) return NotFound("Token not found");

            if (user.TokenExpires < DateTime.UtcNow)
            {
                return Unauthorized("Token expired");
            }

            string token = await CreateTokens(user);

            var driver = await driverManager.GetDriverByLoginUserID(user.LoginUserID);
            if (driver == null) return NotFound("Customer account not found");
            if (driver.IsArchived != null) return NotFound("Archived Driver");

            var retObj = new
            {
                driver = await driverManager.DriverReturn(driver.DriverID),
                token
            };

            return Ok(retObj);
        }

        [HttpPost("RefreshTokenCompany")]
        public async Task<ActionResult<string>> RefreshTokenCompany(RefreshToken refreshTokenObj)
        {
            var refreshToken = refreshTokenObj.Token;

            if (refreshToken == null) return BadRequest("Token not received");

            var user = await loginManager.GetLoginUserByRefreshToken(refreshToken);
            if (user == null) return NotFound("Token not found");

            if (user.TokenExpires < DateTime.UtcNow)
            {
                return Unauthorized("Token expired");
            }

            string token = await CreateTokens(user);

            var company = await companyManager.GetCompanyByLoginUserID(user.LoginUserID).FirstOrDefaultAsync();
            if (company == null) return NotFound("Company account not found");

            var retObj = new
            {
                company = await companyManager.CompanyReturn(company.CompanyID, user.LoginUserID),
                token,
                user.RefreshToken,

            };

            return Ok(retObj);
        }

        /// <summary>
        /// This is used to encrypt the password. Manually call this when setting company user
        /// </summary>
        /// <param name="userID"></param>
        /// <returns></returns>
        [HttpGet("encrypt")]
        public async Task<ActionResult> EncryptPassword()
        {
            var loginuser = await ctx.LoginUsers.Where(x => x.PasswordHash == null && x.Password != null).ToListAsync();
            
            foreach (var user in loginuser)
            {
                userService.CreatePasswordHash(user.Password, out byte[] passwordHash, out byte[] passwordSalt);
                user.Password = null;
                user.PasswordHash = passwordHash;
                user.PasswordSalt = passwordSalt;
            }

            await ctx.SaveChangesAsync();
            return Ok("Success");

        }

        private async Task<string> CreateTokens(LoginUser user)
        {
            string token = userService.CreateToken(user);
            var refreshToken = userService.GenerateRefreshToken();
            SetRefreshToken(refreshToken, user);
            await ctx.SaveChangesAsync();
            return token;
        }

        private void SetRefreshToken(RefreshToken newRefreshToken, LoginUser user)
        {
            var cookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Expires = newRefreshToken.Expires
            };

            Response.Cookies.Append("refreshToken", newRefreshToken.Token, cookieOptions);

            user.RefreshToken = newRefreshToken.Token;
            user.TokenCreated = newRefreshToken.Created;
            user.TokenExpires = newRefreshToken.Expires;
        }


    }
}
