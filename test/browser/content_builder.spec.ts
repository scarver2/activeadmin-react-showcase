// test/browser/content_builder.spec.ts

import { expect, test } from "@playwright/test"

test("composes and persists the normalized document with keyboard controls", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/content_builder")
  await page.getByRole("button", { name: "Add callout" }).click()
  await page.getByRole("textbox", { name: "Content" }).fill("Browser-composed callout")
  await page.getByRole("button", { name: "Move Browser-composed callout up" }).click()
  await page.getByRole("button", { name: "Save document" }).click()
  await expect(page.getByRole("region", { name: "Live preview" })).toContainText("Browser-composed callout")
  await page.reload()
  await expect(page.getByRole("region", { name: "Live preview" })).toContainText("Browser-composed callout")
})
