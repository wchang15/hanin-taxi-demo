using Npgsql;

namespace KoreanTaxi.Data;

public static class DemoDatabase
{
    public static string Validate(string? connectionString)
    {
        var connection = new NpgsqlConnectionStringBuilder(connectionString ?? "");
        if (connection.Host is not ("127.0.0.1" or "localhost" or "::1") ||
            connection.Database?.StartsWith("hanin_demo_", StringComparison.Ordinal) != true)
            throw new InvalidOperationException("PostgreSQL demo requires a loopback host and a separate hanin_demo_* database.");
        return connection.ConnectionString;
    }
}
