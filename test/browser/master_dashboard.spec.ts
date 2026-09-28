// test/browser/master_dashboard.spec.ts

import { expect, test } from "@playwright/test"

test("master dashboard moves from glance to inspect to act", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page.getByRole("heading", { name: "See the operation." })).toBeVisible()
  await page.goto("/admin")

  await expect(page.getByRole("heading", { name: "See the operation." })).toBeVisible()
  await expect(page.locator("[data-test-site-title]")).toHaveText("Texas Bluebonnet")
  await expect(page.locator("body")).toHaveAttribute("data-activeadmin-theme", "texas-bluebonnet")
  await expect(page.locator("#main-menu")).not.toBeInViewport()
  await page.mouse.move(1, 1)
  await expect(page.locator(".master-domain-trigger")).toHaveCount(4)
  await expect(page.locator(".master-domain-indicators > span")).toHaveCount(12)
  await expect(page.getByText(/Focus, hover, or tap a domain/)).toBeVisible()
  await expect(page.getByText("Why it matters")).toHaveCount(0)
  await expect(page.getByText("Privacy", { exact: true })).toHaveCount(0)
  await expect(page.getByRole("button", { name: /Sales & Relationships: Healthy/ })).toBeVisible()
  await expect(page.getByRole("button", { name: /Production & Content: Attention/ })).toBeVisible()
  await expect(page.getByRole("button", { name: /Operations: Stable/ })).toBeVisible()
  await expect(page.getByRole("button", { name: /Collaboration & Reporting: Healthy/ })).toBeVisible()

  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: 1000 })
    for (const dark of [false, true]) {
      await page.locator("html").evaluate((html, value) => html.classList.toggle("dark", value), dark)
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
      if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
        await page.screenshot({ fullPage: true, path: `docs/screenshots/master-dashboard-${width}-${dark ? "dark" : "light"}.png` })
      }
    }
  }

  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.locator("html").evaluate(html => html.classList.remove("dark"))
  const sales = page.getByRole("button", { name: /Sales & Relationships: Healthy/ })
  await sales.hover()
  await expect(page.getByRole("navigation", { name: "Sales & Relationships actions" })).toBeVisible()
  await expect(page.getByText("Why it matters")).toBeVisible()
  await expect(page.getByRole("link", { name: /Account Data Explorer/ })).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/master-dashboard-disclosure-sales.png" })

  const production = page.getByRole("button", { name: /Production & Content: Attention/ })
  await production.focus()
  await page.mouse.move(1, 1)
  await expect(page.getByRole("navigation", { name: "Production & Content actions" })).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/master-dashboard-disclosure-production.png" })

  const operations = page.getByRole("button", { name: /Operations: Stable/ })
  await operations.click()
  await page.mouse.move(0, 0)
  await expect(page.getByRole("navigation", { name: "Operations actions" })).toBeVisible()
  await expect(page.getByRole("button", { name: /Operations: Stable.*pinned/ })).toHaveAttribute("aria-expanded", "true")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/master-dashboard-disclosure-operations.png" })

  await page.setViewportSize({ width: 390, height: 1000 })
  await page.getByRole("button", { name: /Collaboration & Reporting: Healthy/ }).click()
  await page.mouse.move(0, 0)
  await expect(page.getByRole("navigation", { name: "Collaboration & Reporting actions" })).toBeVisible()
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)

  await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
  await expect(page.locator("#main-menu")).toBeInViewport()
  await page.keyboard.press("Escape")
  await expect(page.locator("#main-menu")).not.toBeInViewport()

  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.getByRole("button", { name: /Operations: Stable/ }).click()
  await page.getByRole("link", { name: /Calendar Scheduler/ }).click()
  await expect(page).toHaveURL(/\/admin\/calendar_scheduler$/)
})
