using KoreanTaxi.Data;
using KoreanTaxi.Managers;
using KoreanTaxi.Models;
using System.Threading;

public class BackgroundWorkerServiceMatching : BackgroundService
{
    readonly ILogger<BackgroundWorkerServiceMatching> _logger;
    private readonly IServiceScopeFactory _factory;

    public BackgroundWorkerServiceMatching(ILogger<BackgroundWorkerServiceMatching> logger, IServiceScopeFactory factory)
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
            await manager.MatchTrip();
            await Task.Delay(3000, stoppingToken); // 3sec
        }
    }
}