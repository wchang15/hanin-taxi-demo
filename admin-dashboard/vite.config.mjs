import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // timer-queue uses EventEmitter; Vite does not inject Node.js browser shims.
  resolve: {
    alias: [
      { find: /^events$/, replacement: 'events/events.js' },
      // MUI 5's deep icon imports otherwise select CommonJS default wrappers.
      { find: /^@mui\/icons-material\/(?!esm\/)(.+)$/, replacement: '@mui/icons-material/esm/$1' },
    ],
  },
  build: { outDir: 'build' },
  server: { host: '127.0.0.1' },
  preview: { host: '127.0.0.1' },
});
