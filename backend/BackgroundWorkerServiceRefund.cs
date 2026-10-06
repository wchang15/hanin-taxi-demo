using KoreanTaxi.Data;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using System.Threading;

public class BackgroundWorkerServiceRefund : BackgroundService
{
    readonly ILogger<BackgroundWorkerServiceRefund> _logger;
    private readonly IServiceScopeFactory _factory;

    public BackgroundWorkerServiceRefund(ILogger<BackgroundWorkerServiceRefund> logger, IServiceScopeFactory factory)
    {
        _logger = logger;
        _factory = factory;

    }

    protected async override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await using AsyncServiceScope asyncScope = _factory.CreateAsyncScope();
            var manager = asyncScope.ServiceProvider.GetRequiredService<BackgroundManager>();
            await manager.Refund();
            await Task.Delay(86400000, stoppingToken); // day
        }
    }
}
