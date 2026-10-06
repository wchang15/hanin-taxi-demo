using KoreanTaxi.Data;
using KoreanTaxi.Models.NonDBModels;
using KoreanTaxi.Models;
using KoreanTaxi.Services;
using Microsoft.EntityFrameworkCore;
using KoreanTaxi.Models.Enums;
using System.Linq.Expressions;
using Microsoft.AspNetCore.Mvc;

namespace KoreanTaxi.Managers
{
    public class CustomerManager
    {
        private readonly TaxiDbContext ctx;
        private readonly IStripeService stripeService;
        private readonly ITwilioService twilioService;

        public CustomerManager(TaxiDbContext ctx, IStripeService stripeService, ITwilioService twilioService)
        {
            this.ctx = ctx;
            this.stripeService = stripeService;
            this.twilioService = twilioService;
        }

        public async Task<Customer> RegisterCustomer(RegisterRequest request, long loginUserID)
        {
            var customer = new Customer(loginUserID, request.FirstName, request.LastName, request.Email, request.Language, request.Terms);
            customer.PhoneNumber = request.PhoneNumber;
            ctx.Customers.Add(customer);
            await ctx.SaveChangesAsync();
            return customer;
        }

        public IQueryable<Customer> GetCustomerByLoginUserID(long loginUserID)
        {
            var customerObj = ctx.Customers.Where(x => x.LoginUser.IsActive && x.LoginUserID == loginUserID);
            return customerObj;
        }

        public IQueryable<Customer> GetCustomer(long customerID)
        {
            var customer = ctx.Customers.Where(x => x.CustomerID == customerID && x.LoginUser.IsActive);
            return customer;
        }

        public IQueryable<Customer> GetCustomerWithOTP(string otp)
        {
            var customer = ctx.Customers.Where(x => x.AuthNumber == otp && x.LoginUser.IsActive);
            return customer;
        }

        public IQueryable<Customer> GetCustomerDynamicWhere(params Expression<Func<Customer, bool>>[] wheres)
        {
            return wheres.Aggregate(ctx.Customers.Where(x => x.LoginUser.IsActive).AsQueryable(), (customer, where) => customer.Where(where));
        }


        public async Task<Customer?> GetCustomerWithDupPhoneNumber(string number, long userID)
        {
            var customer = await ctx.Customers.Where(x => x.PhoneNumber == number && userID != x.LoginUserID && x.IsVerified).FirstOrDefaultAsync();
            return customer;
        }

        public void ResetAuthNumber(Customer customer)
        {
            customer.AuthNumber = null;
            ctx.SaveChanges();
        }

        public async Task<bool> SendAuthNumber(Customer customer, string phoneNumberOverride = "")
        {
            Random random = new Random();
            string rand = random.Next(10000, 99999).ToString();

            var number = phoneNumberOverride != "" ? phoneNumberOverride : customer.PhoneNumber;

            var validatePhone = await twilioService.ValidatePhoneNumber(number);
            if (!validatePhone) return false;
            var sendSMS = await twilioService.SendSMS(number, rand);
            if (!sendSMS) return false;

            customer.AuthNumber = rand;

            await ctx.SaveChangesAsync();

            return true;
        }


        public async Task<string> AddStripeCustomer(Models.Customer customer)
        {
            var stripeCustomerID = await stripeService.CreateStripeCustomerAsync(customer);
            customer.StripeCustomerID = stripeCustomerID;
            await ctx.SaveChangesAsync();
            return stripeCustomerID;
        }

        /// <summary>
        /// Method <c>AddSearchHistory</c> adds an instance of a user's search to their search history
        /// </summary>
        public async Task<CustomerSearchHistory> AddSearchHistory(long customerId, long googleLocationID)
        {
            //check for inputting duplicate records
            CustomerSearchHistory? potentialDuplicate = await ctx.CustomerSearchHistories.Where(x => x.CustomerID == customerId && x.GoogleLocationID == googleLocationID).FirstOrDefaultAsync();
            if (potentialDuplicate != null) return potentialDuplicate;

            //check if there are more than 5 search history instances
            var historyLength = await ctx.CustomerSearchHistories.Where(x => x.CustomerID == customerId).CountAsync();
            if (historyLength > 5)
            {
                //remove oldest search history
                CustomerSearchHistory? staleHistory = await ctx.CustomerSearchHistories.Where(x => x.CustomerID == customerId).OrderByDescending(x => x.CreatedDateTime).FirstOrDefaultAsync();
                ctx.CustomerSearchHistories.Remove(staleHistory);
            }

            //create and update a new customer search history
            var newSearchHistory = new CustomerSearchHistory
            {
                CustomerID = customerId,
                GoogleLocationID = googleLocationID
            };

            //add instance to DB and save changes
            await ctx.CustomerSearchHistories.AddAsync(newSearchHistory);
            await ctx.SaveChangesAsync();
            return newSearchHistory;
        }

        public async Task<CustomerSavedLocation> SaveLocation(long customerID, long googleLocationID, EnumSavedLocationType type)
        {
            var customerSavedLocation = new CustomerSavedLocation
            {
                CustomerID = customerID,
                GoogleLocationID = googleLocationID,
                Type = type
            };

            await ctx.CustomerSavedLocations.AddAsync(customerSavedLocation);
            await ctx.SaveChangesAsync();

            return customerSavedLocation;
        }

        public async Task<CustomerCard?> GetDefaultCard(long customerID)
        {
            var customer = await ctx.Customers.Where(x => x.LoginUser.IsActive && x.CustomerID == customerID).FirstOrDefaultAsync();
            var customerCard = await ctx.CustomerCards.Where(x => x.CustomerCardID == customer.DefaultCardID).FirstOrDefaultAsync();
            return customerCard;
        }

        public async Task<List<UserCard>> GetAllCards(long customerID)
        {
            var savedCards = new List<UserCard>();
            var cards = await ctx.CustomerCards.Include(x => x.Customer).Where(x => x.CustomerID == customerID && !x.IsRemoved).OrderByDescending(x => x.Customer.DefaultCardID == x.CustomerCardID).ToListAsync();
            foreach (var c in cards)
            {
                savedCards.Add(new UserCard(c));
            }
            return savedCards;
        }

        public async Task<CustomerReturn> CustomerReturn(Customer customer)
        {
            var ret = new CustomerReturn(customer);

            var user = await ctx.LoginUsers.Where(x => x.LoginUserID == customer.LoginUserID).FirstOrDefaultAsync();

            ret.UserName = user.Username;

            var card = await GetDefaultCard(customer.CustomerID);
            if (card != null) ret.DefaultCardID = card.CustomerCardID;

            ret.SavedCards = await GetAllCards(customer.CustomerID);

            var searchHistories = await ctx.CustomerSearchHistories.Include(x => x.GoogleLocation).Where(x => x.CustomerID == customer.CustomerID).OrderByDescending(x => x.CreatedDateTime).Take(5).ToListAsync();
            foreach (var history in searchHistories)
            {
                ret.SearchHistories.Add(new UserLocation(history.GoogleLocation));
            }

            var savedLocations = await ctx.CustomerSavedLocations.Include(x => x.GoogleLocation).Where(x => x.CustomerID == customer.CustomerID).OrderByDescending(x => x.CreatedDateTime).ToListAsync();
            foreach (var location in savedLocations)
            {
                ret.SavedLocations.Add(new UserLocation(location.GoogleLocation, location.Type));
            }

            return ret;
        }



    }

}
