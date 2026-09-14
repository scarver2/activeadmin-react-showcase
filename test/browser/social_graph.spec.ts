// test/browser/social_graph.spec.ts

import { expect, test } from "@playwright/test"

test("expands and selects the Rails-bounded social graph", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/social_network")
  await expect(page.getByTestId("social-graph").locator("canvas").first()).toBeVisible()
  await page.getByRole("button", { name: "3 degrees" }).click()
  await expect(page.getByRole("region", { name: "People" })).toContainText("Maya Singh")
  await page.getByRole("button", { name: "June Park" }).click()
  await expect(page.getByRole("region", { name: "Selected person" })).toContainText("Mission planner")
  await page.getByRole("button", { name: "Fit graph" }).click()
})
