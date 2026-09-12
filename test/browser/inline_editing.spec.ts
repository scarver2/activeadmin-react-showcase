// test/browser/inline_editing.spec.ts

import { expect, test } from "@playwright/test"

test("keyboard-edits one small island, restores focus, and persists after reload", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/inline_editing")

  const button = page.getByRole("button", { name: "Edit Status for Bluebonnet Logistics" })
  await button.focus()
  await page.keyboard.press("Enter")
  const editor = page.getByLabel("Status for Bluebonnet Logistics")
  await expect(editor).toBeFocused()
  await editor.selectOption("trial")
  await page.keyboard.press("Enter")
  await expect(button).toHaveText("trial")
  await expect(button).toBeFocused()
  await page.reload()
  await expect(page.getByRole("button", { name: "Edit Status for Bluebonnet Logistics" })).toHaveText("trial")
  await expect(page.getByRole("row", { name: /Bluebonnet Logistics/ }).getByText("Region locked while trial")).toBeVisible()
  await page.getByRole("link", { name: "Open full record" }).first().click()
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+/)
})
