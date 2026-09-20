// test/browser/theme_integration.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

test("applies the V3 recipe to native ActiveAdmin and React-island surfaces", async ({ page }) => {
  await signIn(page)

  await expect(page.getByRole("heading", { name: /A place for every part/ })).toBeVisible()
  const tokens = await page.locator("body").evaluate((body) => {
    const styles = getComputedStyle(body)
    return {
      background: styles.getPropertyValue("--aat-background").trim(),
      border: styles.getPropertyValue("--aat-border").trim(),
      focus: styles.getPropertyValue("--aat-focus").trim(),
      surface: styles.getPropertyValue("--aat-surface").trim()
    }
  })
  expect(tokens).toEqual({ background: "#f3f4f5", border: "#87929c", focus: "#175eac", surface: "#fff" })

  await page.goto("/admin/accounts")
  await expect(page.locator("table.data-table")).toBeVisible()
  await page.goto("/admin/admin_users/new")
  const email = page.getByLabel("Email")
  await email.focus()
  await expect(email).toBeFocused()
  expect(await email.evaluate((element) => getComputedStyle(element).outlineStyle)).not.toBe("none")

  await page.goto("/admin/data_explorer")
  await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/activeadmin-v3-theme.png" })
  }
})

test("keeps the themed server fallback useful without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await signIn(page)
  await page.goto("/admin/data_explorer")

  await expect(page.getByText(/Accounts available without JavaScript/)).toBeVisible()
  await expect(page.getByRole("link", { name: "Browse Rails-owned Accounts" })).toBeVisible()
  expect(await page.locator("body").evaluate((body) => getComputedStyle(body).getPropertyValue("--aat-surface").trim()))
    .toBe("#fff")

  await context.close()
})
