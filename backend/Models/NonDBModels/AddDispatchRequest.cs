namespace KoreanTaxi.Models.NonDBModels
{
    public class AddDispatchRequest
    {
        public string UserName { get; set; }
        public string Password { get; set; }
        public string DispatchName { get; set; }
        public long CompanyID { get; set; }
    }
}
