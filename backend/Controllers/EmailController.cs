using KoreanTaxi.Managers;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MimeKit;
using MimeKit.Text;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    //[Authorize(Roles = nameof(EnumUserRole.COMPANY))]
    public class EmailController : ControllerBase
    {
        private readonly IEmailService emailService;
        private readonly IUserService userService;
        private readonly CustomerManager customerManager;

        public EmailController(IEmailService emailService, IUserService userService, CustomerManager customerManager)
        {
            this.emailService = emailService;
            this.userService = userService;
            this.customerManager = customerManager;
        }

        [HttpPost("SendEmailToHanin")]
        public async Task<IActionResult> SendEmail(EmailRequest req)
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
            var customer = await customerManager.GetCustomerByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (customer == null) return NotFound("The Customer information not found.");

            var tripID = req.TripID == null || req.TripID == 0 ? "Undefined" : req.TripID.ToString();
            var title = $"Screen {req.Screen} : Customer {customer.CustomerID} : Trip {tripID}";
            var message = $"Customer {customer.CustomerID} : {customer.Fullname} sent an Email. \n{req.Message}";

            emailService.SendEmailToHanin(title, message);

            return Ok();
        }
    }
}
