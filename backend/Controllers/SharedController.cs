using KoreanTaxi.Data;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Controllers
{

    [Route("api/[controller]")]
    [ApiController]
    public class SharedController : ControllerBase
    {
        private readonly TaxiDbContext ctx;
        private readonly IGoogleService googleService;
        private readonly TripManager tripManager;

        public SharedController(TaxiDbContext ctx, IGoogleService googleService, TripManager tripManager)
        {
            this.ctx = ctx;
            this.googleService = googleService;
            this.tripManager = tripManager;
        }

        [HttpGet("GetAutoComplete"), Authorize(Roles = nameof(EnumUserRole.CUSTOMER) + ", " + nameof(EnumUserRole.DRIVER) + ", " + nameof(EnumUserRole.COMPANY))]
        public async Task<IActionResult> GetAutoComplete(string address)
        {

            var googleRes = await googleService.GetAutoComplete(address);

            address = address.Replace(" ", "").ToLower();
            // Name to check without spaces
            var dbRes = await ctx.CompanyGoogleLocations.Include(x => x.GoogleLocation).Where(x => x.Name.Replace(" ","").ToLower().Contains(address)).Select(x => new GoogleLocation
            {
                PreferredName = x.Name,
                Name = x.GoogleLocation.Name,
                Address = x.GoogleLocation.Address,
                Latitude = x.GoogleLocation.Latitude,
                Longitude = x.GoogleLocation.Longitude,
                LocationType = x.GoogleLocation.LocationType
            }).ToListAsync();

            dbRes.AddRange(googleRes);

            return Ok(dbRes);

        }

        [HttpPost("SaveAddress"), Authorize(Roles = nameof(EnumUserRole.COMPANY))]
        public async Task<IActionResult> SaveAddress(CompanyLocationRequest req)
        {
            var googleLocation = await tripManager.GetGoogleLocation(req.Address, req.Name, req.Latitude, req.Longitude, req.LocationType);
            
            if (req.PreferredName != string.Empty)
            {
                var companyGoogleLocation = await ctx.CompanyGoogleLocations.FirstOrDefaultAsync(x => x.GoogleLocationID == googleLocation.GoogleLocationID);
                if (companyGoogleLocation != null)
                {
                    companyGoogleLocation.Name = req.PreferredName;
                }
                else
                {
					companyGoogleLocation = new CompanyGoogleLocation()
					{
						GoogleLocationID = googleLocation.GoogleLocationID,
						Name = req.PreferredName
					};
					await ctx.CompanyGoogleLocations.AddAsync(companyGoogleLocation);
				}
                await ctx.SaveChangesAsync();
            }

            return Ok("Success");
        }

        //[HttpGet("GetAutoCompleteTest")]
        //public async Task<IActionResult> GetAutoCompleteTest(string address)
        //{

        //    var googleRes = await googleService.GetAutoComplete(address);

        //    foreach (var g in googleRes)
        //    {
        //        g.State = tripManager.GetState(g.Name, g.Address);
        //    }

        //    address = address.Replace(" ", "").ToLower();
        //    // Name to check without spaces
        //    var dbRes = await ctx.CompanyGoogleLocations.Include(x => x.GoogleLocation).Where(x => x.Name.Replace(" ", "").ToLower().Contains(address)).Select(x => new GoogleLocation
        //    {
        //        PreferredName = x.Name,
        //        Name = x.GoogleLocation.Name,
        //        Address = x.GoogleLocation.Address,
        //        Latitude = x.GoogleLocation.Latitude,
        //        Longitude = x.GoogleLocation.Longitude,
        //        LocationType = x.GoogleLocation.LocationType
        //    }).ToListAsync();

        //    dbRes.AddRange(googleRes);

           

        //    return Ok(dbRes);

        //}

    }
}