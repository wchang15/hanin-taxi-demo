using KoreanTaxi.Hubs;
using KoreanTaxi.Models.Enums;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace KoreanTaxi.Managers
{
    public class HubManager
    {
        private readonly IHubContext<TaxiHub> hubContext;

        public HubManager(IHubContext<TaxiHub> hubContext) {
            this.hubContext = hubContext;
        }
        public async Task SendToClient<T>(string groupName, string method, EnumTripStatus tripStatus, T obj)
        {
            await hubContext.Clients.Group(groupName).SendAsync(method, tripStatus, obj);
        }
        public async Task SendToClient(string groupName, string method, EnumTripStatus tripStatus)
        {
            await hubContext.Clients.Group(groupName).SendAsync(method, tripStatus);
        }
        public async Task SendToClient<T>(string groupName, string method, long tripID, T obj)
        {
            await hubContext.Clients.Group(groupName).SendAsync(method, obj, tripID);
        }
    }
}
