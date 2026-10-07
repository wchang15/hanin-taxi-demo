using KoreanTaxi.Controllers;
using KoreanTaxi.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace KoreanTaxi.Services;

// Covers legacy GET actions that write too. Dispatch owns its fresh context and
// transaction separately; nesting that transaction here would deadlock.
public sealed class DemoDatabaseTransactionFilter(TaxiDbContext context) : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext executing, ActionExecutionDelegate next)
    {
        if (executing.Controller is DemoController)
        {
            await next();
            return;
        }
        await using var transaction = await DispatchTransaction.BeginAsync(context, executing.HttpContext.RequestAborted);
        var executed = await next();
        var status = (executed.Result as ObjectResult)?.StatusCode
            ?? (executed.Result as StatusCodeResult)?.StatusCode ?? executing.HttpContext.Response.StatusCode;
        if (transaction != null && executed.Exception == null && status < 400)
            await transaction.CommitAsync(executing.HttpContext.RequestAborted);
    }
}
