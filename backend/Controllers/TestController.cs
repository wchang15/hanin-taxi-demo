using KoreanTaxi.Data;
using KoreanTaxi.Helper;
using KoreanTaxi.Managers;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TestController : ControllerBase
    {

        private readonly TaxiDbContext ctx;


        public TestController(TaxiDbContext ctx)
        {
            this.ctx = ctx;

        }

        [HttpGet("CompanyCount")]
        public async Task<IActionResult> GetCompanyCount()
        {
            var companyCount = await ctx.Companies.CountAsync();
            return Ok(companyCount);
        }




    }
}
