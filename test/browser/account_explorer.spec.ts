// test/browser/account_explorer.spec.ts

import { expect, test } from "@playwright/test"

test("sorts, filters, and paginates the authenticated Rails account dataset", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await page.getByRole("button", { name: "Toggle section" }).filter({ hasText: "Data & Reporting" }).click()
  await page.getByRole("link", { name: "Account Data Explorer" }).click()

  await expect(page).toHaveURL(/\/admin\/data_explorer/)
  await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")
  await expect(page.getByRole("row").filter({ hasText: "Bluebonnet Logistics" })).toBeVisible()

  const responsePromise = page.waitForResponse((response) => response.url().includes("/admin/data-explorer/accounts?"))
  await page.getByLabel("Search name").fill("Cedar")
  await page.getByRole("button", { name: "Apply filters" }).click()
  expect((await responsePromise).status()).toBe(200)
  await expect(page.getByTestId("account-explorer-results")).toContainText("1 account")
  await expect(page.getByRole("link", { name: "Cedar Ridge Health" })).toBeVisible()

  await page.getByLabel("Search name").fill("")
  await page.getByRole("button", { name: "Apply filters" }).click()
  await page.getByRole("button", { name: "Sort by name" }).click()
  await expect(page.getByRole("row").nth(1)).toContainText("Trinity River Foods")
  await page.getByRole("button", { name: "Next" }).click()
  await expect(page.getByText("Page 2 of 2")).toBeVisible()

  await expect(page.getByRole("heading", { name: "Demo" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Ruby" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "JavaScript" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Architecture", exact: true })).toBeVisible()
})
