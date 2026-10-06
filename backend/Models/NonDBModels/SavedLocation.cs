using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class SavedLocation
    {
        public long GoogleLocationID { get; set; }

        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public EnumSavedLocationType Type { get; set; } = EnumSavedLocationType.FAVORITE;
        public EnumLocationType LocationType { get; set; } = EnumLocationType.OTHER;

        public double Longitude { get; set; }
        public double Latitude { get; set; }

        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;
    }
}
