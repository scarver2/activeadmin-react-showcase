// test/browser/onboarding_wizard.spec.ts

import { expect, test } from "@playwright/test"

test("persists and completes the conditional onboarding wizard", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin$/)
  await page.goto("/admin/onboarding_wizard")
  await page.getByLabel("Company name").fill(`Browser Works ${Date.now()}`)
  await page.getByLabel("Account kind").selectOption("regulated")
  await page.getByLabel("Compliance contact").fill("Casey Reviewer")
  await page.getByRole("button", { name: "Save and continue" }).click()
  await expect(page.getByText("Primary contact")).toBeVisible()
  await page.reload()
  await expect(page.getByText("Primary contact")).toBeVisible()
  await page.getByLabel("Email").fill("browser@example.test")
  await page.getByRole("button", { name: "Save and continue" }).click()
  await expect(page.getByRole("heading", { name: "Review", exact: true })).toBeVisible()
  await page.getByRole("button", { name: "Submit application" }).click()
  await expect(page.getByText("Application submitted")).toBeVisible()
})
