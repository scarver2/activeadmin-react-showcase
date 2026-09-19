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

test("persists the header theme switcher across React and image-editing surfaces", async ({ page }) => {
  await page.setViewportSize({ height: 1000, width: 1440 })
  await signIn(page)
  await page.goto("/admin/data_explorer")
  await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")

  const selector = page.getByLabel("Visual theme")
  await expect(selector).toHaveValue("v3")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/theme-v3-classic.png" })
  }

  await selector.selectOption("v3_texas")
  await expect.poll(() => themeToken(page, "--aat-background")).toBe("#f2eee5")
  await page.reload()
  await expect(page.getByLabel("Visual theme")).toHaveValue("v3_texas")
  await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/theme-texas-bluebonnet.png" })
  }

  await page.goto("/admin/image_annotation_editor")
  await expect(page.getByTestId("image-annotation-editor")).toBeVisible()
  await expect(page.getByLabel(/Source image editor/)).toHaveCSS("background-color", "rgb(20, 43, 61)")
  await expect(page.getByRole("button", { name: "Crop tool" })).toHaveCSS("background-color", "rgb(255, 250, 240)")
})

test("persists a theme through the server-rendered fallback without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await signIn(page)

  await page.getByLabel("Visual theme").selectOption("v3_texas")
  await page.getByRole("button", { name: "Apply theme" }).click()

  await expect(page.locator('[data-showcase-theme-marker="v3_texas"]')).toBeVisible()
  expect(await themeToken(page, "--aat-background")).toBe("#f2eee5")
  await context.close()
})
