using KoreanTaxi.Data;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using System.Threading;

public class BackgroundWorkerServiceCustomerQueue : BackgroundService
{
    readonly ILogger<BackgroundWorkerServiceCustomerQueue> _logger;
    private readonly IServiceScopeFactory _factory;

    public BackgroundWorkerServiceCustomerQueue(ILogger<BackgroundWorkerServiceCustomerQueue> logger, IServiceScopeFactory factory)
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
            await manager.RemoveCompletedCustomerQueue();
            await manager.RemoveDriverCanceledCustomerQueue();
            await manager.RemovePendingCustomerQueue(); //if pending for more than 30 of created time, there is a problem : Remove
            await manager.EncrpytPassword();
            await Task.Delay(3600000, stoppingToken); //hour
        }
    }
}