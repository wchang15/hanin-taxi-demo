using KoreanTaxi.Data;
using KoreanTaxi.Models;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Services;
using Microsoft.EntityFrameworkCore;

namespace KoreanTaxi.Managers
{
    public class CompanyManager
    {

        private readonly TaxiDbContext ctx;


        public CompanyManager(TaxiDbContext ctx)
        {
            this.ctx = ctx;
        }

        public IQueryable<Company> GetCompanyByLoginUserID(long loginUserID)
        {
            var company = ctx.CompanyUsers.Include(x => x.Company).Where(x => x.LoginUserID == loginUserID).Select(x => x.Company);
            return company;
        }

        public IQueryable<CompanyCustomerPhoneNumber> GetCompanyCustomerPhoneNumbers(long companyID)
        {
            return ctx.CompanyCustomerPhoneNumbers.Where(x => x.CompanyID == companyID);
        }

        public async Task InsertIntoCompanyCustomerPhoneNumber(long companyID, long? googleLocationID, string phoneNumber, string? customerName = "")
        {
            var cpn = new CompanyCustomerPhoneNumber()
            {
                CompanyID = companyID,
                PhoneNumber = phoneNumber,
                CustomerName = customerName,
                GoogleLocationID = googleLocationID,
            };

            await ctx.CompanyCustomerPhoneNumbers.AddAsync(cpn);
            await ctx.SaveChangesAsync();
        }

        public async Task UpdateCompanyCustomerPhoneNumber(long companyCustomerPhoneNumberID, long companyID, long? googleLocationID, string phoneNumber, string customerName)
        {
            var record = await ctx.CompanyCustomerPhoneNumbers.Where(x => x.CompanyCustomerPhoneNumberID== companyCustomerPhoneNumberID && x.CompanyID == companyID).FirstOrDefaultAsync();
            if (record == null) return;
            record.GoogleLocationID = googleLocationID;
            record.PhoneNumber = phoneNumber;
            record.CustomerName = customerName;
            await ctx.SaveChangesAsync();
        }

        public async Task<string> DeleteCompanyCustomerPhoneNumber(long companyCustomerPhoneNumberID, long companyID)
        {
            var record = await ctx.CompanyCustomerPhoneNumbers.Where(x => x.CompanyCustomerPhoneNumberID == companyCustomerPhoneNumberID && x.CompanyID == companyID).FirstOrDefaultAsync();
            if (record != null)
            {
                ctx.CompanyCustomerPhoneNumbers.Remove(record);
                await ctx.SaveChangesAsync();
                return record.CustomerName;
            }
            return string.Empty;
        }


        public async Task<CompanyReturn> CompanyReturn(long companyID, long userID)
        {
            var companyUser = await ctx.CompanyUsers.Include(x => x.Company).ThenInclude(x => x.Drivers).ThenInclude(x => x.Taxi).Include(x => x.LoginUser).Where(x => x.CompanyID == companyID && x.LoginUserID == userID).FirstOrDefaultAsync();    
            var ret = new CompanyReturn(companyUser);

            //foreach (var driver in company.Drivers)
            //{
            //    ret.Drivers.Add(new DriverReturn(driver));
            //}

            return ret;
        }



    }
}
