using KoreanTaxi.Models.Enums;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.ComponentModel.DataAnnotations.Schema;

namespace KoreanTaxi.Models
{
    public class CustomerSavedLocation
    {
        public long CustomerSavedLocationID { get; set; }
        public long CustomerID { get; set; }
        public long GoogleLocationID { get; set; }
        public EnumSavedLocationType Type { get; set; } = EnumSavedLocationType.FAVORITE;
        public DateTime CreatedDateTime { get; set; } = DateTime.UtcNow;

        public virtual Customer? Customer { get; set; }
        public virtual GoogleLocation? GoogleLocation { get; set; }

    }
}
