using KoreanTaxi.Data;
using KoreanTaxi.Helper;
using KoreanTaxi.Models.Enums;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel;
using System.Linq;

namespace KoreanTaxi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EnumController : ControllerBase
    {

        private readonly Dictionary<string, Enum> enumDict = new Dictionary<string, Enum>()
        {
            { nameof(EnumTaxiColor).ToLower(), (EnumTaxiColor)1 }
        };

        [HttpGet("{name}")]
        public IActionResult GetEnumCardCompany(string name)
        {
            if (!enumDict.ContainsKey(name.ToLower())) return NotFound();
            return Ok(EnumToList(enumDict[name.ToLower()]));
        }

        private static List<object> EnumToList(Enum enumValue)
        {
            var list = new List<object>();
            var enumType = enumValue.GetType();
            var dict = Enum.GetValues(enumType)
                .Cast<Enum>()
                .ToDictionary(t => (int)(object)t, t => DbHelper.GetDescription(t));
            foreach (var item in dict)
                list.Add(new { id = item.Key, value = item.Value });
            return list;
        }


    }
}
