using KoreanTaxi.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TaxiController : ControllerBase
    {

        private readonly TaxiDbContext ctx;

        public TaxiController(TaxiDbContext ctx)
        {
            this.ctx = ctx;
        }

        [HttpGet("Events")]
        public async Task<IActionResult> GetEvents()
        {
            var events = await ctx.Events.OrderByDescending(x => x.EventStartDate).ThenByDescending(x => x.EventEndDate).ToListAsync();
            return Ok(events);
        }


    }
}
