using KoreanTaxi.Models.Enums;
using System.ComponentModel.DataAnnotations;

namespace KoreanTaxi.Models
{
    public class CompanyUser
    {

        public long CompanyUserID { get; set; }
        public long CompanyID { get; set; }
        public long LoginUserID { get; set; }
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public virtual Company Company { get; set; }
        public virtual LoginUser LoginUser { get; set; }
    }
}
