// vitest.config.ts

import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

export default defineConfig({
  plugins: [react()],
  test: {
    include: ["app/frontend/**/*.test.{ts,tsx}"],
    coverage: {
      include: ["app/frontend/components/**/*.tsx"],
      provider: "v8",
      reporter: ["text", "html", "lcov"],
      thresholds: {
        branches: 100,
        functions: 100,
        lines: 100,
        statements: 100
      }
    },
    environment: "jsdom",
    globals: true,
    setupFiles: "./test/javascript/setup.ts"
  }
})
