import { spawn } from "node:child_process";
import { randomBytes } from "node:crypto";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

export function startDemo({
  port = 5050,
  autoMatch = true,
  noBuild = false,
  stdio = "inherit",
} = {}) {
  if (!Number.isInteger(port) || port < 1024 || port > 65535)
    throw new Error("Use a port between 1024 and 65535.");
  return spawn(
    process.env.DOTNET_BIN || "dotnet",
    [
      "run",
      "--project",
      path.join(root, "backend/KoreanTaxi.csproj"),
      "--no-launch-profile",
      "--configuration",
      "Release",
      ...(noBuild ? ["--no-build"] : []),
    ],
    {
      cwd: path.join(root, "backend"),
      stdio,
      env: {
        ...process.env,
        DemoMode: "true",
        Dispatch__AutoMatch: String(autoMatch),
        AppSettings__Token: randomBytes(48).toString("hex"),
        ASPNETCORE_ENVIRONMENT: "Development",
        ASPNETCORE_URLS: `http://127.0.0.1:${port}`,
        DOTNET_CLI_TELEMETRY_OPTOUT: "1",
        DOTNET_GENERATE_ASPNET_CERTIFICATE: "false",
        DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE: "false",
        Logging__LogLevel__Default: "Warning",
      },
    }
  );
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href
) {
  const port = Number(process.env.PORT || 5050);
  const child = startDemo({ port });
  console.log(
    `Local-only demo: http://127.0.0.1:${port} (in-memory data; no real payments)`
  );
  child.on("error", (error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
  child.on("exit", (code) => {
    process.exitCode = code ?? 1;
  });
  process.on("SIGINT", () => child.kill("SIGINT"));
  process.on("SIGTERM", () => child.kill("SIGTERM"));
}
