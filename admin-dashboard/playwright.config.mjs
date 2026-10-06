import { defineConfig, devices } from '@playwright/test';

const apiPort = 5796;
const webPort = 4196;

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list'], ['json', { outputFile: 'test-results/results.json' }]],
  timeout: 30_000,
  use: {
    baseURL: `http://127.0.0.1:${webPort}`,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 1000 } } },
    { name: 'mobile', use: { ...devices['iPhone 13'], defaultBrowserType: 'chromium' } },
  ],
  webServer: [
    {
      command: 'node ../scripts/start-demo.mjs',
      env: { PORT: String(apiPort) },
      url: `http://127.0.0.1:${apiPort}/api/Demo/Status`,
      reuseExistingServer: false,
      timeout: 120_000,
    },
    {
      command: 'node e2e/serve.mjs',
      env: {
        E2E_WEB_PORT: String(webPort),
        VITE_API_ADDRESS: `http://127.0.0.1:${apiPort}/api`,
        VITE_HUB_ADDRESS: `http://127.0.0.1:${apiPort}/Taxi`,
      },
      url: `http://127.0.0.1:${webPort}/login`,
      reuseExistingServer: false,
      timeout: 120_000,
    },
  ],
});
