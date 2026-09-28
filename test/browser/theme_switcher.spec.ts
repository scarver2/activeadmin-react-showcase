// test/browser/theme_switcher.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

async function themeToken(page: import("@playwright/test").Page, name: string) {
  return page.locator("body").evaluate((body, property) => getComputedStyle(body).getPropertyValue(property).trim(), name)
}

test("persists color palettes across unchanged React and image-editing surfaces", async ({ page }) => {
  await page.setViewportSize({ height: 1000, width: 1440 })
  await signIn(page)
  await page.goto("/admin/data_explorer")
  await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")

  const selector = page.getByLabel("Color palette")
  await expect(selector).toHaveValue("v3")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/palette-classic-neutral.png" })
  }

  await selector.selectOption("v3_texas")
  await expect.poll(() => themeToken(page, "--aat-background")).toBe("#f2eee5")
  await page.reload()
  await expect(page.getByLabel("Color palette")).toHaveValue("v3_texas")
  await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/palette-limestone-ink.png" })
  }

  await page.goto("/admin/image_annotation_editor")
  await expect(page.getByTestId("image-annotation-editor")).toBeVisible()
  await expect(page.getByLabel(/Source image editor/)).toHaveCSS("background-color", "rgb(20, 43, 61)")
  await expect(page.getByRole("button", { name: "Crop tool" })).toHaveCSS("background-color", "rgb(255, 250, 240)")

  const saved = page.waitForResponse(response => response.url().includes("theme-preference") && response.request().method() === "PATCH")
  await page.getByLabel("Color palette").selectOption("v3_slate")
  await saved
  await page.reload()
  await expect(page.getByLabel("Color palette")).toHaveValue("v3_slate")
  await expect(page.getByLabel(/Source image editor/)).toHaveCSS("background-color", "rgb(21, 43, 50)")
  await page.goto("/admin/data_explorer")
  await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")
  await expect.poll(() => themeToken(page, "--aat-background")).toBe("#edf1f2")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/palette-slate-copper.png" })
  }
})

test("persists a palette through the server-rendered fallback without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await signIn(page)
  await page.goto("/admin/accounts")

  await page.getByLabel("Color palette").selectOption("v3_texas")
  await page.getByRole("button", { name: "Apply palette" }).click()

  await expect(page.locator('[data-showcase-theme-marker="v3_texas"]')).toBeVisible()
  expect(await themeToken(page, "--aat-background")).toBe("#f2eee5")
  await context.close()
})
