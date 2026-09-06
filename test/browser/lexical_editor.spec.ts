// test/browser/lexical_editor.spec.ts

import { expect, test } from "@playwright/test"

test("creates, validates, preserves, and edits a Lexical article", async ({ page }) => {
  const browserErrors: string[] = []
  page.on("pageerror", (error) => browserErrors.push(error.message))

  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
  await expect(page.getByRole("heading", { name: "Showcase Home" })).toBeVisible()

  await page.goto("/admin/showcase_articles/new")
  await expect(page.locator('[data-react-component="LexicalEditor"]')).toHaveCount(1)
  const editor = page.getByRole("textbox", { name: "Article body" })
  await expect(editor).toBeVisible()
  expect(browserErrors).toEqual([])
  await editor.fill("Browser draft survives validation")
  await page.getByLabel("Summary").fill("Real Chromium exercises the normal form boundary.")
  await page.getByRole("button", { name: "Create Showcase article" }).click()

  await expect(page.getByText("can't be blank", { exact: true })).toBeVisible()
  expect(browserErrors).toEqual([])
  await expect(page.getByRole("textbox", { name: "Article body" })).toContainText("Browser draft survives validation")

  await page.getByLabel("Title").fill("Browser-authored Lexical article")
  await page.getByRole("button", { name: "Create Showcase article" }).click()

  await expect(page).toHaveURL(/\/admin\/showcase_articles\/\d+$/)
  await expect(page.getByText("Browser draft survives validation")).toBeVisible()
  await page.getByRole("link", { name: "Edit Showcase Article" }).click()

  const restoredEditor = page.getByRole("textbox", { name: "Article body" })
  await expect(restoredEditor).toContainText("Browser draft survives validation")
  await restoredEditor.fill("Browser edit persisted through Lexical")
  await page.getByRole("button", { name: "Update Showcase article" }).click()

  await expect(page.getByText("Browser edit persisted through Lexical")).toBeVisible()
})
