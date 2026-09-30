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
    await page.screenshot({ path: "docs/screenshots/contextual-inspector-1440-light.png" })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await page.screenshot({ path: "docs/screenshots/contextual-inspector-1440-dark.png" })
    await page.locator("html").evaluate(element => element.classList.remove("dark"))
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
  await expect.poll(async () => (await inspector.boundingBox())?.x).toBeCloseTo(0, 3)
  const bounds = await inspector.boundingBox()
  expect(bounds?.width).toBeCloseTo(390, 3)
  expect(await inspector.evaluate(element => element.scrollWidth <= element.clientWidth)).toBe(true)
  await expect(page.getByRole("button", { name: "Close account inspector" })).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ path: "docs/screenshots/contextual-inspector-390-light.png" })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await page.screenshot({ path: "docs/screenshots/contextual-inspector-390-dark.png" })
  }
})

test("reuses the Rails-backed inspector from the dense ActiveAdmin account index", async ({ page }) => {
  await signIn(page)
  await page.goto("/admin/accounts")

  const inspect = page.getByRole("link", { name: "Inspect" }).first()
  await inspect.click()

  const dialog = page.getByRole("dialog")
  await expect(dialog).toBeVisible()
  await expect(dialog.getByRole("heading", { level: 2 })).toHaveText(/\S+/)
  await expect(dialog.getByRole("link", { name: "View full account" })).toHaveAttribute("href", /\/admin\/accounts\/\d+$/)
  await page.goBack()
  await expect(dialog).toBeHidden()
  await expect(inspect).toBeFocused()
})

test("presents stale and changed-authorization recovery without leaking old context", async ({ page }) => {
  await signIn(page)
  await openExplorer(page)
  const accountLink = page.getByRole("link", { name: "Bluebonnet Logistics" })
  const inspectorHref = await accountLink.getAttribute("data-account-inspector")
  if (!inspectorHref) throw new Error("Inspector endpoint is missing")

  await page.route(inspectorHref, route => route.fulfill({ contentType: "application/json", status: 404, body: "{}" }))
  await accountLink.click()
  await expect(page.getByRole("alert")).toContainText("no longer available")
  await expect(page.getByRole("link", { name: "Return to the account list" })).toHaveAttribute("href", "/admin/accounts")
  await page.goBack()
  await page.unroute(inspectorHref)

  await page.route(inspectorHref, route => route.fulfill({ contentType: "application/json", status: 401, body: "{}" }))
  await page.goForward()
  await expect(page.getByRole("alert")).toContainText("authorization changed")
  await expect(page.getByRole("link", { name: "Reauthenticate on the canonical account page" })).toHaveAttribute("href", /\/admin\/accounts\/\d+$/)
  await expect(page.getByText("Latest activity")).toHaveCount(0)
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

  await page.goto("/admin/accounts")
  const fallback = page.getByRole("link", { name: /Open Bluebonnet Logistics/ })
  await expect(fallback).toHaveAttribute("href", /\/admin\/accounts\/\d+$/)
  await context.close()
})
