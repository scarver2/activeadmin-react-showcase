// playwright.config.ts

import { defineConfig, devices } from "@playwright/test"

const port = 3100

export default defineConfig({
  expect: { timeout: 10_000 },
  fullyParallel: false,
  reporter: "list",
  testDir: "./test/browser",
  use: {
    baseURL: `http://127.0.0.1:${port}`,
    trace: "retain-on-failure"
  },
  webServer: {
    command: `PORT=${port} bin/browser-server`,
    reuseExistingServer: false,
    timeout: 120_000,
    url: `http://127.0.0.1:${port}/up`
  },
  workers: 1,
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] }
    }
  ]
})
