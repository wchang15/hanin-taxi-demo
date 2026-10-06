using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace KoreanTaxi.Hubs
{
    public class TaxiHub : Hub
    {
        //Not being used
        public Task SendMessage(string connectionID, string trip)
        {

            //await Clients.Client(connectionId: connectionID).SendAsync("Taxi", trip);
            return Clients.All.SendAsync("Taxi", trip);
        }

        //[Authorize(Roles = nameof(EnumUserRole.CUSTOMER) + ", " + nameof(EnumUserRole.DRIVER) + ", " + nameof(EnumUserRole.COMPANY))]
        public async Task AddToGroup(string groupName)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        }
    }
}
