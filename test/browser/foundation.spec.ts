// test/browser/foundation.spec.ts

import { expect, test } from "@playwright/test"

test("mounts the activeadmin-react master dashboard in Chromium", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()

  await expect(page).toHaveURL(/\/admin/)
  await expect(page.getByRole("heading", { name: /Run the whole operation/ })).toBeVisible()
  await expect(page.locator(".master-metric-value")).toHaveCount(3)
  await expect(page.locator(".master-metric-value").first()).toHaveText("6")
  await expect(page.getByRole("region", { name: "Sales & Relationships" })).toBeVisible()
})
