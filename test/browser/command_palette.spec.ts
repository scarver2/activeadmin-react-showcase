// test/browser/command_palette.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

test("searches authorized records through a real keyboard-accessible palette", async ({ page }) => {
  await signIn(page)
  await page.goto("/admin/command_palette")

  await expect(page.getByRole("heading", { name: "Demo" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Ruby" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "JavaScript" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Architecture", exact: true })).toBeVisible()

  await page.keyboard.press("Control+k")
  const input = page.getByRole("combobox", { name: "Search pages, accounts and articles" })
  await expect(input).toBeFocused()
  await input.fill("Calendar")
  const response = page.waitForResponse((candidate) => candidate.url().includes("/admin/global-search?"))
  await page.getByRole("dialog").getByRole("button", { name: "Search", exact: true }).click()
  expect((await response).status()).toBe(200)
  await expect(page.getByRole("option").filter({ hasText: "Calendar Scheduler" })).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/command-palette.png" })
  }
  await input.press("Enter")
  await expect(page).toHaveURL(/\/admin\/calendar_scheduler$/)

  await page.getByRole("button", { name: /Search Showcase/ }).click()
  const accountInput = page.getByRole("combobox", { name: "Search pages, accounts and articles" })
  await accountInput.fill("Bluebonnet")
  await page.getByRole("dialog").getByRole("button", { name: "Search", exact: true }).click()
  await expect(page.getByRole("option").filter({ hasText: "Bluebonnet Logistics" })).toBeVisible()
  await accountInput.press("Enter")
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+$/)

  await page.goto("/admin/command_palette")
  await page.getByRole("button", { name: /Search Showcase/ }).click()
  await page.getByRole("combobox", { name: "Search pages, accounts and articles" }).fill("record-that-does-not-exist")
  await page.getByRole("dialog").getByRole("button", { name: "Search", exact: true }).click()
  await expect(page.getByTestId("command-palette-empty")).toBeVisible()

  await page.route("**/admin/global-search?**", async (route) => {
    await route.fulfill({ body: JSON.stringify({ error: "Search is temporarily unavailable" }), contentType: "application/json", status: 503 })
  }, { times: 1 })
  await page.getByRole("combobox", { name: "Search pages, accounts and articles" }).fill("Bluebonnet")
  await page.getByRole("dialog").getByRole("button", { name: "Search", exact: true }).click()
  await expect(page.getByRole("alert")).toContainText("Search is temporarily unavailable")
  await page.getByRole("combobox", { name: "Search pages, accounts and articles" }).press("Escape")
  await expect(page.getByRole("button", { name: /Search Showcase/ })).toBeFocused()
})

test("keeps authenticated search and navigation useful without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await signIn(page)

  await page.goto("/admin/command_palette")
  await expect(page.getByText("Search remains available as an ordinary authenticated Rails form")).toBeVisible()
  await page.getByLabel("Search pages, accounts and articles").fill("Bluebonnet")
  await page.getByRole("button", { name: "Search", exact: true }).click()
  await expect(page).toHaveURL(/\/admin\/command_palette\?q=Bluebonnet/)
  const account = page.getByRole("link", { name: "Account: Bluebonnet Logistics" })
  await expect(account).toBeVisible()
  await account.click()
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+$/)
  await context.close()
})
