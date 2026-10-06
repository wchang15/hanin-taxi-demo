using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class StateDefaultLocation
    {
        public long StateDefaultLocationID { get; set; }
        public EnumState State { get; set; }
        [Column(TypeName = "decimal(9,6)")]
        public double Longitude { get; set; }
        [Column(TypeName = "decimal(8,6)")]
        public double Latitude { get; set; }
    }
}
