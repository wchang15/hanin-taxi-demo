

using KoreanTaxi.Data;
using KoreanTaxi.Managers;
//using KoreanTaxi.Migrations;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Net.NetworkInformation;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReportController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IUserService userService;
        private readonly CompanyManager companyManager;

        public ReportController(TaxiDbContext ctx, IUserService userService, CompanyManager companyManager)
        {
            this.ctx = ctx;
            this.userService = userService;
            this.companyManager = companyManager;
        }

        [Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        [HttpGet("GetCompanyReports")]
        public async Task<IActionResult> GetCompanyReports()
        {
            var userID = userService.GetUserID();
            if (userID == null) return BadRequest("Please sign in again");
           
            var company = await companyManager.GetCompanyByLoginUserID(userID.Value).FirstOrDefaultAsync();
            if (company == null) return NotFound("The Company information not found.");

            var reports = await ctx.Trips
                .Include(t => t.Payment)
                .Include(t => t.Driver)
                .Where(t => (t.Payment == null || t.Payment.PaymentStatus == EnumPaymentStatus.PAID) && t.TripStatus == EnumTripStatus.COMPLETED && t.Driver.CompanyID == company.CompanyID && t.Driver.IsArchived == null)
                .GroupBy(tpd => new { tpd.Driver.DriverID, tpd.Driver.FirstName, tpd.Driver.DriverNumber})
                .Select(g => new Report()
                {
                    DriverID = g.Key.DriverNumber,
                    FirstName = g.Key.FirstName,
                    TripAmount = g.Where(x => x.CustomerID != null).Sum(tpd => tpd.MileageAmount + tpd.TollAmount),
                    TipAmount = g.Where(x => x.CustomerID != null).Sum(tpd => tpd.Payment.TipAmount),
                    TaxAmount = g.Where(x => x.CustomerID != null).Sum(tpd => tpd.CalledTaxiSize == EnumTaxiSize.SMALL ? tpd.SmallStateFeeAmount : tpd.LargeStateFeeAmount),
                    TotalAmount = g.Where(x => x.CustomerID != null).Sum(tpd => tpd.Payment.CardAmount + tpd.Payment.PointAmount + tpd.Payment.TipAmount),
                    Mileage = g.Where(x => x.CustomerID != null).Sum(tpd => tpd.Mileage),
                    TripCount = g.Where(x => x.TripType != EnumTripType.CARD).Count(),    // Cash trip count
                }).ToListAsync();

            return Ok(reports);

        }
    }
}

