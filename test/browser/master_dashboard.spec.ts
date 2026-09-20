// test/browser/master_dashboard.spec.ts

import { expect, test } from "@playwright/test"

test("master dashboard, one global palette and session Privacy Mode", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page.getByRole("heading", { name: /A place for every part/ })).toBeVisible()
  await expect(page.getByTestId("command-palette")).toHaveCount(1)
  await expect(page.getByTestId("private-metric").first()).toHaveText("Hidden")
  const privacy = page.getByRole("button", { name: /Privacy Mode/ })
  const before = await page.locator(".master-overview").boundingBox()
  await privacy.click()
  await expect(privacy).toBeEnabled()
  await expect(privacy).toHaveAttribute("aria-pressed", "false")
  await expect(page.getByTestId("private-metric").first()).toHaveText("6")
  expect((await page.locator(".master-overview").boundingBox())?.height).toBe(before?.height)
  await page.reload()
  await expect(privacy).toHaveAttribute("aria-pressed", "false")
  await privacy.click()
  await expect(privacy).toBeEnabled()
  await expect(page.getByTestId("private-metric").first()).toHaveText("Hidden")
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
  await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
  await expect(page.locator("#main-menu")).toBeInViewport()
  await page.keyboard.press("Escape")
  await expect(page.locator("#main-menu")).not.toBeInViewport()
  await page.keyboard.press("Control+k")
  await expect(page.getByRole("dialog")).toHaveCount(1)
  await page.getByRole("combobox", { name: "Search pages, accounts and articles" }).fill("Calendar")
  await page.getByRole("button", { name: "Search", exact: true }).click()
  await expect(page.getByRole("option").filter({ hasText: "Calendar Scheduler" })).toBeVisible()
  await page.getByRole("dialog").getByRole("link", { name: /Calendar Scheduler/ }).click()
  await expect(page).toHaveURL(/\/admin\/calendar_scheduler$/)
  await expect(page.getByTestId("command-palette")).toHaveCount(1)
  await expect(page.getByRole("button", { name: /Privacy Mode/ })).toHaveAttribute("aria-pressed", "true")
})
