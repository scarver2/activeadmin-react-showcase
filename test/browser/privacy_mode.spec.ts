// test/browser/privacy_mode.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

test("masks the three designated dashboard totals and persists in the administrator session", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await signIn(page)

  const privacy = page.getByRole("button", { name: /Privacy Mode/ })
  const metrics = page.getByTestId("private-metric")
  const before = await page.getByTestId("foundation-status").boundingBox()
  await expect(privacy).toHaveAttribute("aria-pressed", "true")
  await expect(metrics).toHaveText(["Hidden", "Hidden", "Hidden"])
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/privacy-mode-1440.png" })

  await page.setViewportSize({ width: 390, height: 1000 })
  await page.reload()
  await expect(metrics).toHaveText(["Hidden", "Hidden", "Hidden"])
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/privacy-mode-390.png" })

  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.reload()

  const saved = page.waitForResponse(response => response.url().includes("/admin/privacy-mode") && response.request().method() === "PATCH")
  await privacy.click()
  expect((await saved).status()).toBe(200)
  await expect(privacy).toHaveAttribute("aria-pressed", "false")
  await expect(metrics.first()).not.toHaveText("Hidden")
  const visibleValues = await metrics.allTextContents()
  expect(visibleValues).toHaveLength(3)
  expect(visibleValues).not.toContain("Hidden")
  expect((await page.getByTestId("foundation-status").boundingBox())?.height).toBe(before?.height)

  await page.reload()
  await expect(privacy).toHaveAttribute("aria-pressed", "false")
  await expect(metrics).toHaveText(visibleValues)
})

test("keeps the session toggle available through the ordinary Rails fallback", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await signIn(page)

  const privacy = page.getByRole("button", { name: "Privacy Mode On" })
  await expect(privacy).toHaveAttribute("aria-pressed", "true")
  await privacy.click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await expect(page.getByRole("button", { name: "Privacy Mode Off" })).toHaveAttribute("aria-pressed", "false")
  await context.close()
})
