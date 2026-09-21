// test/browser/master_dashboard.spec.ts

import { expect, test } from "@playwright/test"

test("master dashboard composes the operating picture and application launcher", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page.getByRole("heading", { name: /A place for every part/ })).toBeVisible()
  const metrics = page.locator(".master-metric-value")
  await expect(metrics).toHaveCount(3)
  await expect(metrics.nth(0)).toHaveText("6")
  await expect(metrics.nth(1)).toHaveText(/^\d{1,3}(?:,\d{3})*$/)
  await expect(metrics.nth(2)).toHaveText(/^\$\d{1,3}(?:,\d{3})*$/)
  await expect(page.getByRole("region", { name: "Sales & Relationships" })).toContainText("Account Data Explorer")
  await expect(page.getByRole("region", { name: "Production & Content" })).toContainText("Kanban Workflow")
  await expect(page.getByRole("region", { name: "Operations" })).toContainText("Calendar Scheduler")
  await expect(page.getByRole("region", { name: "Collaboration & Reporting" })).toContainText("Analytics")
  await page.getByLabel("Color palette").selectOption("v3_texas")
  await expect(page.locator('[data-showcase-theme-marker="v3_texas"]')).toBeVisible()

  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: 1000 })
    for (const dark of [false, true]) {
      await page.locator("html").evaluate((html, value) => html.classList.toggle("dark", value), dark)
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
      if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: `docs/screenshots/master-dashboard-${width}-${dark ? "dark" : "light"}.png` })
    }
  }
  const paletteSaved = page.waitForResponse(response => response.url().includes("theme-preference") && response.request().method() === "PATCH")
  await page.getByLabel("Color palette").selectOption("v3")
  await paletteSaved
  await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
  await expect(page.locator("#main-menu")).toBeInViewport()
  await page.keyboard.press("Escape")
  await expect(page.locator("#main-menu")).not.toBeInViewport()
  await page.getByRole("link", { name: /Calendar Scheduler/ }).click()
  await expect(page).toHaveURL(/\/admin\/calendar_scheduler$/)
})
