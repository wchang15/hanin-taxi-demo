using Geolocation;
using KoreanTaxi.Data;
using KoreanTaxi.Hubs;
using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Services;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Org.BouncyCastle.Crypto.Engines;
using System.ComponentModel.Design;
using USAddress;

namespace KoreanTaxi.Managers
{
    public class BackgroundManager
    {
        private readonly TaxiDbContext ctx;
        private readonly IServiceScopeFactory factory;
        private readonly IHubContext<TaxiHub> hubContext;
        private readonly TripManager tripManager;
        private readonly HubManager hubManager;
        private readonly IDispatchScoringService dispatchScoringService;

        public BackgroundManager(TaxiDbContext ctx, IServiceScopeFactory factory, IHubContext<TaxiHub> hubContext, TripManager tripManager, HubManager hubManager, IDispatchScoringService dispatchScoringService)
        {
            this.ctx = ctx;
            this.factory = factory;
            this.hubContext = hubContext;
            this.tripManager = tripManager;
            this.hubManager = hubManager;
            this.dispatchScoringService = dispatchScoringService;
        }

        public List<AddressParseResult> AddressParserTest()
        {
            AddressParser parser = new AddressParser();
            List<AddressParseResult> addressParseResults = new List<AddressParseResult>();
            var glocation = ctx.GoogleLocations.ToList();
            foreach (var address in glocation)
            {
                var len = address.Address.LastIndexOf("United States");
                if (len < 0) len = address.Address.Length;
                var subadd = address.Address.Substring(0, len);
                var pa = parser.ParseAddress(subadd);
                addressParseResults.Add(pa);
            }
            return addressParseResults;
        }

        public async Task EncrpytPassword()
        {
            var loginuser = await ctx.LoginUsers.Where(x => x.PasswordHash == null && x.Password != null).ToListAsync();

            await using AsyncServiceScope asyncScope = factory.CreateAsyncScope();
            var userService = asyncScope.ServiceProvider.GetRequiredService<IUserService>();

            foreach (var user in loginuser)
            {
                userService.CreatePasswordHash(user.Password, out byte[] passwordHash, out byte[] passwordSalt);
                user.Password = null;
                user.PasswordHash = passwordHash;
                user.PasswordSalt = passwordSalt;
                
            }
            await ctx.SaveChangesAsync();
        }

        public async Task<bool> Refund()
        {
            var refundingPayments = await ctx.Payments.Where(x => x.PaymentStatus == EnumPaymentStatus.REFUNDING).ToListAsync();
            string error = string.Empty;
            int successAmount = 0;
            int errorAmount = 0;

            try
            {
                await using AsyncServiceScope asyncScope = factory.CreateAsyncScope();
                var stripeService = asyncScope.ServiceProvider.GetRequiredService<IStripeService>();
                foreach (var payment in refundingPayments)
                {
                    var errorMsg = stripeService.RefundPayment(payment.PaymentIntentID);
                    if (errorMsg == null)
                    {
                        payment.PaymentStatus = EnumPaymentStatus.REFUNDED;
                        successAmount += 1;
                    }
                    else
                    {
                        error += errorMsg;
                        errorAmount += 1;
                    }
                }
            }
            catch (Exception ex)
            {
                error += ex.Message;
            }
            finally
            {
                ctx.SaveChanges();
                bool err = error != string.Empty;
                if (successAmount > 0 || err)
                {
                    AddToBackgroundHistory(0, 0, successAmount, errorAmount, err, error, "REFUND");
                }
            }

            return true;

        }

        /// <summary>
        /// This is to take care of a bug where Customer queue is pending forever.
        /// </summary>
        /// <returns></returns>
        public async Task RemovePendingCustomerQueue()
        {
            var curTime = DateTime.UtcNow.AddMinutes(-30);
            var customerQueues = ctx.CustomerQueues.Include(x => x.Trip).Where(x => x.QueueStatus == EnumQueueStatus.PENDING && x.CreatedDateTime < curTime);

            var test = customerQueues.ToList();

            ctx.RemoveRange(customerQueues);
            await ctx.SaveChangesAsync();
        }

        /// <summary>
        /// If driver canceled the trip and customer does not respond for 1 hours, (They can call a new taxi) customer makes full payment
        /// </summary>
        /// <returns></returns>
        public async Task<bool> RemoveDriverCanceledCustomerQueue()
        {
            var customerQueues = await ctx.CustomerQueues.Include(x => x.Trip).Where(x => x.QueueStatus == EnumQueueStatus.DRIVERCANCELED).ToListAsync();
            var curTime = DateTime.UtcNow;
            string error = string.Empty;
            int errorAmount = 0;
            int successAmount = 0;

            try
            {
                await using AsyncServiceScope asyncScope = factory.CreateAsyncScope();
                var stripeService = asyncScope.ServiceProvider.GetRequiredService<IStripeService>();
                foreach (var customerQueue in customerQueues)
                {
                    TimeSpan diff = curTime - customerQueue.CreatedDateTime;
                    if (diff.TotalHours > 1)
                    {
                        //make payment as well.
                        try
                        {
                            var payment = customerQueue.Trip.Payment;
                            var isSuccess = stripeService.CompletePayment(payment);
                            if (isSuccess == string.Empty)
                            {
                                payment.PaymentStatus = EnumPaymentStatus.PAID;
                            }
                            ctx.Remove(customerQueue);
                            ctx.SaveChanges();
                            successAmount += 1;
                        }
                        catch (Exception ex)
                        {
                            error += ex.Message;
                            errorAmount += 1;
                        }
                    }
                }
            }

            catch (Exception ex)
            {
                error += ex.ToString();
                Console.WriteLine(error);
            }
            finally
            {
                var cqCount = customerQueues.Count();
                var dqCount = 0;
                bool err = error != string.Empty;
                if (cqCount != 0 || err)
                {
                    AddToBackgroundHistory(cqCount, dqCount, successAmount, errorAmount, err, error, "CUSTOMERQUEUEDRIVERCANCEL");
                }

            }
            await ctx.SaveChangesAsync();
            return true;
        }

        /// <summary>
        /// If customer has outstanding completed trip, it removes the queue after 2 hours.
        /// Customer makes the full payment.
        /// </summary>
        /// <returns></returns>
        public async Task<bool> RemoveCompletedCustomerQueue()
        {
            var customerQueues = await ctx.CustomerQueues.Include(x => x.Trip).ThenInclude(x => x.Payment).Where(x => x.QueueStatus == EnumQueueStatus.ACCEPTED && x.Trip.TripStatus == EnumTripStatus.COMPLETED).ToListAsync();
            var curTime = DateTime.UtcNow;
            string error = string.Empty;
            int errorAmount = 0;
            int successAmount = 0;

            try
            {
                await using AsyncServiceScope asyncScope = factory.CreateAsyncScope();
                var stripeService = asyncScope.ServiceProvider.GetRequiredService<IStripeService>();
                foreach (var customerQueue in customerQueues)
                {
                    TimeSpan diff = curTime - customerQueue.Trip.CompletedTime.Value;
                    if (diff.TotalHours > 2)
                    {
                        //make payment as well.
                        var errMsg = string.Empty;
                        if (customerQueue.CustomerID != null)
                        {
                            errMsg = stripeService.CompletePayment(customerQueue.Trip.Payment);
                        }
                        if (errMsg == string.Empty)
                        {
                            if (customerQueue.CustomerID != null) customerQueue.Trip.Payment.PaymentStatus = EnumPaymentStatus.PAID;
                            ctx.CustomerQueues.Remove(customerQueue);
                            successAmount += 1;
                        }
                        else
                        {
                            error += errMsg;
                            errorAmount += 1;
                        }
                    }
                }
            }

            catch (Exception ex)
            {
                error += ex.ToString();
                Console.WriteLine(error);
            }
            finally
            {
                var cqCount = customerQueues.Count();
                var dqCount = 0;
                bool err = error != string.Empty;
                if (cqCount != 0 || err)
                {
                    AddToBackgroundHistory(cqCount, dqCount, successAmount, errorAmount, err, error, "CUSTOMERQUEUECOMPLETED");
                }

            }
            await ctx.SaveChangesAsync();
            return true;
        }

        /// <summary>
        /// Trip matching algorithm
        /// </summary>
        /// <returns></returns>
        public async Task<bool> MatchTrip()
        {
            var matchedTripCount = 0;
            var error = string.Empty;
            var driverQueues = await ctx.DriverQueues
                .Include(x => x.DriverQueueRejectedCustomerQueues)
                .Include(x => x.Driver)
                    .ThenInclude(x => x.Company)
                    .ThenInclude(x => x.CompanyOperatingStates)
                .Include(x => x.Driver)
                    .ThenInclude(x => x.Taxi)
                .Where(x => x.QueueStatus == EnumQueueStatus.WAITING)
                .OrderBy(x => x.CreatedDateTime)
                .ToListAsync();
            var customerQueues = await ctx.CustomerQueues
                .Include(x => x.Trip)
                    .ThenInclude(x => x.PickupLocation)
                .Include(x => x.Trip)
                    .ThenInclude(x => x.DropoffLocation)
                .OrderBy(x => x.CreatedDateTime)
                .Where(x => x.QueueStatus == EnumQueueStatus.WAITING).ToListAsync();

            try
            {
                var nowUtc = DateTime.UtcNow;
                foreach (var dq in driverQueues)
                {
                    if ((int)(nowUtc - dq.DeclinedTime).TotalSeconds < Constants.DRIVER_MATCH_IDLE_TIME) continue;

                    var bestCandidate = customerQueues
                        .Where(cq => cq.QueueStatus == EnumQueueStatus.WAITING)
                        .Select(cq => new
                        {
                            CustomerQueue = cq,
                            MatchScore = dispatchScoringService.ScoreCandidate(dq, cq, nowUtc)
                        })
                        .Where(x => x.MatchScore.IsEligible)
                        .OrderByDescending(x => x.MatchScore.Score)
                        .ThenBy(x => x.CustomerQueue.CreatedDateTime)
                        .FirstOrDefault();

                    if (bestCandidate == null)
                    {
                        continue;
                    }

                    var cq = bestCandidate.CustomerQueue;
                    dq.QueueStatus = EnumQueueStatus.PENDING;
                    dq.TripID = cq.TripID;
                    dq.CustomerQueueID = cq.CustomerQueueID;
                    cq.QueueStatus = EnumQueueStatus.PENDING;
                    ctx.SaveChanges();
                    matchedTripCount += 1;

                    var tripReturnForDriver = await tripManager.TripReturnForDriver(cq.Trip);
                    await hubManager.SendToClient($"{Constants.DRIVER}{dq.DriverID}", Constants.MATCH, cq.Trip.TripStatus, tripReturnForDriver);
                }
            }
            catch (Exception ex)
            {
                error = ex.ToString();
            }
            finally
            {
                var cqCount = customerQueues.Count();
                var dqCount = driverQueues.Count();
                var err = error != string.Empty;
                if ((cqCount != 0 && dqCount != 0) || err)
                {
                    AddToBackgroundHistory(cqCount, dqCount, matchedTripCount, 0, err, error, "Matching");
                }

            }

            return true;
        }

        private void AddToBackgroundHistory(int cqCount, int dqCount, int successCount, int errorCount, bool err, string errMsg, string process)
        {
            var background = new BackgroundHistory()
            {
                CustomerQueueCount = cqCount,
                DriverQueueCount = dqCount,
                SuccessAmount = successCount,
                ErrorAmount = errorCount,
                Error = errMsg,
                IsSuccess = err,
                Process = process,
                CreatedDateTime = DateTime.UtcNow,
            };
            ctx.BackgroundHistories.Add(background);
            ctx.SaveChanges();

        }

    }
}
