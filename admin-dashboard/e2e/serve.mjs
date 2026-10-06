import { build, preview } from 'vite';

// Keep the test API address out of the normal demo bundle.
await build({ build: { outDir: 'build-e2e' } });
const server = await preview({
  build: { outDir: 'build-e2e' },
  preview: { host: '127.0.0.1', port: Number(process.env.E2E_WEB_PORT), strictPort: true },
});
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.once(signal, () => server.httpServer.close(() => process.exit(0)));
}
