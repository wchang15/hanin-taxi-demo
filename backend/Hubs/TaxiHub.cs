using KoreanTaxi.Models;
using KoreanTaxi.Models.Enums;
using KoreanTaxi.Models.NonDBModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using KoreanTaxi.Services;

namespace KoreanTaxi.Hubs
{
    [Authorize]
    public class TaxiHub(HubGroupAuthorization authorization) : Hub
    {
        public override async Task OnConnectedAsync()
        {
            if (await authorization.ResolveAsync(Context.User, Context.ConnectionAborted) == null)
            {
                Context.Abort();
                return;
            }
            await base.OnConnectedAsync();
        }

        public async Task AddToGroup(string groupName)
        {
            var allowed = await authorization.ResolveAsync(Context.User, Context.ConnectionAborted);
            if (allowed == null || !string.Equals(groupName, allowed, StringComparison.Ordinal))
                throw new HubException("This account cannot subscribe to that channel.");
            await Groups.AddToGroupAsync(Context.ConnectionId, allowed, Context.ConnectionAborted);
        }
    }
}
