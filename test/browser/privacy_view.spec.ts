// test/browser/privacy_view.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

test("conceals semantically marked financial values from the global top navigation", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await signIn(page)

  const privacy = page.getByRole("switch", { name: /Privacy View/ })
  const revenue = page.locator('[data-private="financial"]').first()
  const visibleRevenue = revenue.locator(".privacy-value-content")
  const placeholder = revenue.locator(".privacy-value-placeholder")
  const before = await page.getByTestId("foundation-status").boundingBox()

  await expect(privacy).toHaveAttribute("aria-checked", "false")
  await expect(page.locator("html")).toHaveAttribute("data-privacy-view", "off")
  await expect(visibleRevenue).toHaveText(/^\$[\d,]+$/)
  await expect(visibleRevenue).toBeVisible()
  await expect(placeholder).toBeHidden()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/privacy-view-off-1440.png" })
  }

  const saved = page.waitForResponse(response => response.url().includes("/admin/privacy-view") && response.request().method() === "PATCH")
  await privacy.click()
  expect((await saved).status()).toBe(200)
  await expect(privacy).toHaveAttribute("aria-checked", "true")
  await expect(page.locator("html")).toHaveAttribute("data-privacy-view", "on")
  await expect(visibleRevenue).toBeHidden()
  await expect(placeholder).toBeVisible()
  await expect(placeholder).toContainText("••••")
  await expect(page.getByTestId("foundation-status").locator('[data-private="financial"]')).toHaveCount(1)
  await expect(page.getByTestId("foundation-status").getByText("Accounts")).toBeVisible()
  await expect(page.getByTestId("foundation-status").getByText("Active users")).toBeVisible()
  expect((await page.getByTestId("foundation-status").boundingBox())?.height).toBe(before?.height)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/privacy-view-on-1440.png" })
  }

  await page.reload()
  await expect(page.getByRole("switch", { name: /Privacy View On/ })).toHaveAttribute("aria-checked", "true")
  await expect(page.locator("html")).toHaveAttribute("data-privacy-view", "on")
})

test("applies the same semantic contract to the analytics surface without removing widgets", async ({ page }) => {
  await signIn(page)
  await page.getByRole("switch", { name: /Privacy View/ }).click()
  await page.goto("/admin/analytics")
  await expect(page.getByTestId("analytics-populated")).toBeVisible()

  const privateValues = page.getByTestId("analytics-populated").locator('[data-private="financial"]')
  expect(await privateValues.count()).toBeGreaterThan(3)
  await expect(privateValues.first().locator(".privacy-value-content")).toBeHidden()
  await expect(privateValues.first().locator(".privacy-value-placeholder")).toBeVisible()
  await expect(page.getByRole("img", { name: "Active-user trend chart" })).toBeVisible()
  await expect(page.getByRole("img", { name: "Active users by account chart" })).toBeVisible()
  await expect(page.getByRole("img", { name: "Account plan mix in range chart" })).toBeVisible()
})

test("keeps the global switch available through the ordinary Rails fallback", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await signIn(page)

  const privacy = page.getByRole("switch", { name: "Privacy View Off" })
  await expect(privacy).toHaveAttribute("aria-checked", "false")
  await privacy.click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await expect(page.getByRole("switch", { name: "Privacy View On" })).toHaveAttribute("aria-checked", "true")
  await context.close()
})
