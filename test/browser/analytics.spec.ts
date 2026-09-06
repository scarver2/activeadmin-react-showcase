// test/browser/analytics.spec.ts

import { expect, test } from "@playwright/test"

test("filters the real Rails analytics endpoint and renders Recharts views", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await page.getByRole("button", { name: "Toggle section" }).filter({ hasText: "Data & Reporting" }).click()
  await page.getByRole("link", { name: "Analytics Dashboard" }).click()

  await expect(page).toHaveURL(/\/admin\/analytics/)
  await expect(page.getByTestId("analytics-populated")).toBeVisible()
  await expect(page.getByRole("img", { name: "Active-user trend chart" })).toBeVisible()
  await expect(page.getByRole("img", { name: "Active users by account chart" })).toBeVisible()
  await expect(page.getByRole("img", { name: "Account plan mix in range chart" })).toBeVisible()
  await expect(page.getByRole("table", { name: "Active-user trend data" })).toContainText("Active users")
  await expect(page.getByRole("table", { name: "Active users by account data" })).toContainText("Bluebonnet Logistics")
  await expect(page.getByRole("table", { name: "Account plan mix in range data" })).toContainText("Enterprise")
  await expect(page.getByRole("img", { name: "Active-user trend chart" })).toHaveAttribute("aria-describedby", "active-user-trend-data")

  const endDate = await page.getByLabel("End date").inputValue()
  const responsePromise = page.waitForResponse((response) => (
    response.url().includes("/admin/analytics/data?") && response.url().includes(`end_date=${endDate}`)
  ))

  await page.getByLabel("Start date").fill(endDate)
  await page.getByRole("button", { name: "Refresh analytics" }).click()

  const response = await responsePromise
  expect(response.status()).toBe(200)
  expect((await response.json()).series).toHaveLength(1)
  await expect(page.getByTestId("analytics-populated")).toHaveAttribute("aria-busy", "false")
  await expect(page.getByRole("heading", { name: "Demo" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Ruby" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "JavaScript" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Architecture", exact: true })).toBeVisible()
})
