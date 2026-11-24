import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Built files go to public/admin-app while the app itself is opened at /admin (served by a Laravel
// route). A real public/admin folder would make PHP's built-in server mis-route /admin/* URLs.
export default defineConfig(({ command }) => ({
  base: command === 'build' ? '/admin-app/' : '/admin/',
  plugins: [react()],
  build: {
    outDir: '../public/admin-app',
    emptyOutDir: true,
    chunkSizeWarningLimit: 1500,
  },
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://127.0.0.1:8000',
      '/storage': 'http://127.0.0.1:8000',
    },
  },
}));
