// test/browser/lexical_editor.spec.ts

import { expect, test, type Page } from "@playwright/test"

async function signIn(page: Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
}

test("formats, persists, reloads, and safely renders a rich Lexical document", async ({ page }) => {
  const browserErrors: string[] = []
  page.on("pageerror", (error) => browserErrors.push(error.message))
  await signIn(page)

  await page.goto("/admin/showcase_articles")
  const articleRow = page.getByRole("row").filter({ hasText: "Rich editing stays Rails-owned" })
  await articleRow.getByRole("link", { name: "Edit" }).click()

  const editor = page.getByRole("textbox", { name: "Article body" })
  await expect(editor).toBeVisible()
  await expect(page.getByRole("toolbar", { name: "Document formatting" })).toBeVisible()
  await expect(editor.locator("h2")).toContainText("Rodeo operations briefing")
  await expect(editor.locator("ul li")).toHaveCount(3)
  await expect(editor.locator("blockquote")).toContainText("The browser proposes; Rails disposes.")
  await expect(editor.getByRole("link", { name: "ActiveAdmin project" })).toHaveAttribute("href", "https://activeadmin.info")

  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/lexical-editor.png" })
  }

  await editor.click()
  await page.keyboard.press("Control+End")
  await page.keyboard.press("Enter")
  await page.keyboard.press("Meta+B")
  await page.keyboard.type("Chromium formatting proof")
  await page.keyboard.press("Meta+B")
  await page.getByRole("button", { name: "Update Showcase article" }).click()

  await expect(page).toHaveURL(/\/admin\/showcase_articles\/\d+$/)
  await expect(page.locator("strong", { hasText: "Chromium formatting proof" })).toBeVisible()
  await page.getByRole("link", { name: "Edit Showcase Article" }).click()
  await expect(page.getByRole("textbox", { name: "Article body" })).toContainText("Chromium formatting proof")
  expect(browserErrors).toEqual([])
})

test("preserves the editor state when Rails rejects an unsafe link", async ({ page }) => {
  await signIn(page)
  await page.goto("/admin/showcase_articles/new")

  await page.getByLabel("Title").fill("Rejected browser mutation")
  const editor = page.getByRole("textbox", { name: "Article body" })
  await editor.fill("Keep this draft after rejection")
  await page.keyboard.press("Control+A")
  await page.getByRole("button", { name: "Insert or edit link" }).click()
  await page.getByRole("textbox", { name: "Destination URL" }).fill("javascript:alert(1)")
  await page.getByRole("button", { name: "Apply link" }).click()
  await page.getByRole("button", { name: "Create Showcase article" }).click()

  await expect(page).toHaveURL(/\/admin\/showcase_articles$/)
  await expect(page.getByRole("textbox", { name: "Article body" })).toContainText("Keep this draft after rejection")
  await expect(page.getByRole("alert")).toContainText("must be a valid Lexical document")
})
