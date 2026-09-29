// test/browser/contextual_inspector.spec.ts

import { expect, test, type Page } from "@playwright/test"

async function signIn(page: Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
}

async function openExplorer(page: Page) {
  await page.goto("/admin/data_explorer")
  await expect(page.getByTestId("account-explorer-results")).toBeVisible()
}

test("preserves filtered workspace state through canonical inspector history", async ({ page }) => {
  await page.setViewportSize({ height: 1000, width: 1440 })
  await signIn(page)
  await openExplorer(page)
  await page.getByLabel("Search name").fill("Cedar")
  await page.getByRole("button", { name: "Apply filters" }).click()
  await expect(page.getByTestId("account-explorer-results")).toContainText("1 account")
  const accountLink = page.getByRole("link", { name: "Cedar Ridge Health" })
  await expect(accountLink).toBeVisible()
  await accountLink.scrollIntoViewIfNeeded()
  const workspaceScroll = await page.evaluate(() => window.scrollY)

  await accountLink.click()
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+$/)
  const inspector = page.getByRole("dialog", { name: "Cedar Ridge Health" })
  await expect(inspector).toBeVisible()
  await expect(page.getByRole("button", { name: "Close account inspector" })).toBeFocused()
  await expect(inspector.getByRole("link", { name: "View full account" })).toHaveAttribute("href", /\/admin\/accounts\/\d+$/)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/contextual-inspector-1440.png" })
  }

  await page.goBack()
  await expect(page).toHaveURL(/\/admin\/data_explorer/)
  await expect(inspector).toBeHidden()
  await expect(page.getByLabel("Search name")).toHaveValue("Cedar")
  await expect(accountLink).toBeFocused()
  expect(await page.evaluate(() => window.scrollY)).toBe(workspaceScroll)

  await page.goForward()
  await expect(inspector).toBeVisible()
  await page.keyboard.press("Escape")
  await expect(page).toHaveURL(/\/admin\/data_explorer/)
  await expect(accountLink).toBeFocused()
})

test("fills a narrow viewport without losing accessible dismissal", async ({ page }) => {
  await page.setViewportSize({ height: 844, width: 390 })
  await signIn(page)
  await openExplorer(page)
  await page.getByRole("link", { name: "Bluebonnet Logistics" }).click()

  const inspector = page.getByTestId("contextual-inspector")
  await expect(inspector).toBeVisible()
  expect((await inspector.boundingBox())?.width).toBe(390)
  await expect(page.getByRole("button", { name: "Close account inspector" })).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/contextual-inspector-390.png" })
  }
})

test("keeps canonical account navigation available without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await signIn(page)
  await page.goto("/admin/data_explorer")

  const accountLink = page.getByRole("link", { name: "Bluebonnet Logistics" })
  await expect(accountLink).toHaveAttribute("href", /\/admin\/accounts\/\d+$/)
  await accountLink.click()
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+$/)
  await expect(page.locator("body")).toContainText("Bluebonnet Logistics")
  await context.close()
})
