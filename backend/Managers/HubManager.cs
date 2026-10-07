using KoreanTaxi.Hubs;
using KoreanTaxi.Models.Enums;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using KoreanTaxi.Services;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace KoreanTaxi.Managers
{
    public class HubManager
    {
        private readonly IHubContext<TaxiHub> hubContext;
        private readonly DeferredHubNotifications notifications;
        private static readonly JsonSerializerOptions SnapshotOptions = new(JsonSerializerDefaults.Web)
        {
            ReferenceHandler = ReferenceHandler.IgnoreCycles,
        };

        public HubManager(IHubContext<TaxiHub> hubContext, DeferredHubNotifications notifications) {
            this.hubContext = hubContext;
            this.notifications = notifications;
        }
        public async Task SendToClient<T>(string groupName, string method, EnumTripStatus tripStatus, T obj)
        {
            await Send(groupName, method, [tripStatus, obj]);
        }
        public async Task SendToClient(string groupName, string method, EnumTripStatus tripStatus)
        {
            await Send(groupName, method, [tripStatus]);
        }
        public async Task SendToClient<T>(string groupName, string method, long tripID, T obj)
        {
            await Send(groupName, method, [obj, tripID]);
        }

        private Task Send(string groupName, string method, object?[] arguments)
        {
            var snapshot = arguments.Select(arg => (object?)JsonSerializer.SerializeToElement(arg, SnapshotOptions)).ToArray();
            return notifications.SendAsync(() => hubContext.Clients.Group(groupName).SendCoreAsync(method, snapshot));
        }
    }
}
