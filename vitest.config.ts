// vitest.config.ts

import { execFileSync } from "node:child_process"
import { resolve } from "node:path"

import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

function activeAdminReactRoot() {
  if (process.env.ACTIVEADMIN_REACT_PATH) return resolve(process.env.ACTIVEADMIN_REACT_PATH)

  return execFileSync("bundle", ["show", "activeadmin-react"], { encoding: "utf8" }).trim().split(/\r?\n/).at(-1)!
}

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "active_admin/react": resolve(activeAdminReactRoot(), "app/javascript/active_admin/react/index.js")
    }
  },
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
