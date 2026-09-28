// test/browser/tiny_mce_editor.spec.ts

import { expect, test, type Page } from "@playwright/test"

async function signIn(page: Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
}

test("edits, validates, persists, previews, and remounts one self-hosted TinyMCE instance", async ({ page }) => {
  const browserErrors: string[] = []
  page.on("pageerror", (error) => browserErrors.push(error.message))
  await signIn(page)

  await page.goto("/admin/tiny_mce_articles")
  const row = page.getByRole("row").filter({ hasText: "Self-hosted editing stays Rails-owned" })
  await row.getByRole("link", { name: "Edit" }).click()

  await expect(page.locator(".tox-tinymce")).toHaveCount(1)
  await expect(page.getByRole("button", { name: /Bold/ })).toBeVisible()
  const editorFrame = page.locator(".tox-edit-area iframe")
  const editorBody = editorFrame.contentFrame().locator("body")
  await expect(editorBody.getByRole("heading", { name: "Modern editing, familiar boundary" })).toBeVisible()
  await expect(editorBody.getByText("The browser proposes; Rails sanitizes and persists.")).toBeVisible()

  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/tinymce-editor.png" })
  }

  await page.getByLabel("Title").fill("")
  await editorBody.evaluate((body) => {
    const range = document.createRange()
    range.selectNodeContents(body)
    range.collapse(false)
    const selection = window.getSelection()
    selection?.removeAllRanges()
    selection?.addRange(range)
    ;(body as HTMLElement).focus()
  })
  await page.keyboard.press("Enter")
  await editorBody.type("Validation preserves this draft.")
  await page.getByRole("button", { name: "Update TinyMCE Article" }).click()

  await expect(page.getByText("can't be blank")).toBeVisible()
  await expect(page.locator(".tox-tinymce")).toHaveCount(1)
  await expect(page.locator(".tox-edit-area iframe").contentFrame().getByText("Validation preserves this draft.")).toBeVisible()

  await page.getByLabel("Title").fill("Self-hosted editing stays Rails-owned")
  await page.getByRole("button", { name: "Update TinyMCE Article" }).click()
  await expect(page).toHaveURL(/\/admin\/tiny_mce_articles\/\d+$/)
  await expect(page.getByTestId("tinymce-preview")).toContainText("Validation preserves this draft.")

  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/tinymce-preview.png" })
  }

  await page.getByRole("link", { name: "Edit TinyMCE Article" }).click()
  await expect(page.locator(".tox-tinymce")).toHaveCount(1)
  await page.getByRole("link", { name: "TinyMCE Editor" }).click()
  await expect(page.locator(".tox-tinymce")).toHaveCount(0)
  await row.getByRole("link", { name: "Edit" }).click()
  await expect(page.locator(".tox-tinymce")).toHaveCount(1)
  expect(browserErrors).toEqual([])
})

test("keeps a meaningful textarea when JavaScript is disabled", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()

  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await page.goto("/admin/tiny_mce_articles/new")

  await expect(page.locator("textarea#tiny_mce_article_body_html")).toBeVisible()
  await page.locator("textarea#tiny_mce_article_body_html").fill("<h2>No-JavaScript draft</h2><p>Rails still accepts this field.</p>")
  await page.getByLabel("Title").fill("No-JavaScript article")
  await page.getByRole("button", { name: "Create TinyMCE Article" }).click()

  await expect(page.getByTestId("tinymce-preview")).toContainText("No-JavaScript draft")
  await context.close()
})
