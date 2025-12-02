import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import { resolve } from "path";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [svelte()],
  base: "./", // Use relative paths for electron
  resolve: {
    alias: {
      // Point directly to the TypeScript source file
      "@shared": resolve(__dirname, "../shared/index.ts"),
    },
  },
  build: {
    outDir: "../dist/renderer/",
    sourcemap: true, // Enable source maps for debugging
    assetsDir: ".", // Put assets in the same directory as index.html
  },
  server: {
    strictPort: true, // Ensure server always uses port 5173
    hmr: {
      overlay: false, // Disable the HMR overlay to reduce overhead
    },
    watch: {
      usePolling: false, // Disable polling for file changes
    },
  },
});
