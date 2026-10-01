// test/browser/theme_studio.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
}

test("edits semantic tokens across representative previews", async ({ page }) => {
  await page.setViewportSize({ height: 1100, width: 1440 })
  await signIn(page)
  await page.goto("/admin/theme_studio")
  await expect(page.getByTestId("theme-studio")).toBeVisible()
  await expect(page.getByRole("heading", { name: "Composition is fixed" })).toBeVisible()
  await page.getByLabel("Canvas light").fill("#ffffff")
  await expect(page.getByTestId("recipe-proposal")).toContainText('background: "#ffffff"')
  await page.getByLabel("Surface", { exact: true }).selectOption("form")
  await expect(page.getByRole("heading", { name: "Edit account" })).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/theme-studio-1440-light.png" })
  await page.getByRole("button", { name: "dark", exact: true }).click()
  await page.getByRole("button", { name: "narrow", exact: true }).click()
  await page.setViewportSize({ height: 900, width: 390 })
  await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
  await page.keyboard.press("Escape")
  await page.getByLabel("Surface", { exact: true }).selectOption("table")
  await expect(page.getByRole("columnheader", { name: "Account" })).toBeVisible()
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/theme-studio-390-dark.png" })
  await page.getByRole("button", { name: "Reset", exact: true }).focus()
  await page.keyboard.press("Enter")
  await page.getByRole("button", { name: "light", exact: true }).click()
  await expect(page.getByLabel("Canvas light")).toHaveValue("#f3f4f5")
})

test.describe("canonical theme contract", () => {
  test.use({ javaScriptEnabled: false })
  test("remains inspectable without JavaScript", async ({ page }) => {
    await signIn(page)
    await page.goto("/admin/theme_studio")
    await expect(page.getByRole("heading", { name: "ActiveAdmin V3 baseline" })).toBeVisible()
    await expect(page.getByText("JavaScript is optional: the canonical recipe contract remains inspectable.")).toBeVisible()
  })
})
