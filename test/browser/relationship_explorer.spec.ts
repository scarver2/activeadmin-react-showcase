// test/browser/relationship_explorer.spec.ts

import { expect, test } from "@playwright/test"

test("explores Rails-owned account and contact relationships", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await page.getByRole("button", { name: "Toggle section" }).filter({ hasText: "Collaboration" }).click()
  await page.getByRole("link", { name: "Relationship Explorer" }).click()

  await expect(page).toHaveURL(/\/admin\/relationship_explorer/)
  await expect(page.getByTestId("relationship-explorer-results")).toContainText("6 accounts")
  await expect(page.getByRole("link", { name: "Bluebonnet Logistics" })).toBeVisible()
  await expect(page.getByRole("link", { name: "Marisol Vega" })).toBeVisible()

  const responsePromise = page.waitForResponse((response) => (
    response.url().includes("/admin/relationship-explorer/accounts?") &&
      response.url().includes("query=Integration+Engineer")
  ))
  await page.getByLabel("Search accounts or contacts").fill("Integration Engineer")
  await page.getByRole("button", { name: "Apply filters" }).click()

  const response = await responsePromise
  expect(response.status()).toBe(200)
  expect((await response.json()).total).toBe(1)
  await expect(page.getByTestId("relationship-explorer-results")).toContainText("1 account")
  await expect(page.getByRole("link", { name: "Priya Nair" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Demo" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Ruby" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "JavaScript" })).toBeVisible()
  await expect(page.getByRole("heading", { name: "Architecture", exact: true })).toBeVisible()

  await page.getByRole("link", { name: "Priya Nair" }).click()
  await expect(page).toHaveURL(/\/admin\/contacts\/\d+$/)
  await expect(page.getByRole("heading", { name: "Priya Nair" })).toBeVisible()
  await expect(page.getByRole("row", { name: /Email priya\.nair@bluebonnet-logistics\.example/ })).toBeVisible()
  await expect(page.getByRole("row", { name: "Relationship Role Technical lead" })).toBeVisible()
})
