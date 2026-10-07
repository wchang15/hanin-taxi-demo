namespace KoreanTaxi.Services;

// Request-scoped post-commit delivery, not a durable outbox. Failed delivery must
// not turn an already committed command into an apparent HTTP failure.
public sealed class DeferredHubNotifications(ILogger<DeferredHubNotifications> logger)
{
    private readonly List<Func<Task>> pending = [];
    private bool deferring;

    public void Begin() => deferring = true;

    public Task SendAsync(Func<Task> send)
    {
        if (!deferring) return send();
        pending.Add(send);
        return Task.CompletedTask;
    }

    public async Task FlushAsync()
    {
        var committed = pending.ToArray();
        Discard();
        foreach (var send in committed)
        {
            try { await send(); }
            catch (Exception error) { logger.LogWarning(error, "Committed trip update could not be delivered over SignalR; clients must refresh state."); }
        }
    }

    public void Discard()
    {
        pending.Clear();
        deferring = false;
    }
}
