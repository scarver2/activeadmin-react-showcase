// test/browser/audit_history.spec.ts

import { expect, test } from "@playwright/test"

test("filters history and loads a restoration preview", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin$/)
  await page.goto("/admin/audit_history")
  await expect(page.getByRole("heading", { name: /History for/ })).toBeVisible()
  await page.getByLabel("Changed field").selectOption("plan")
  await page.getByRole("button", { name: /Preview restoration/ }).first().click()
  await expect(page.getByText(/no changes applied/)).toBeVisible()
})
