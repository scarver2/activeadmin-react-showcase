// test/browser/ckeditor_editor.spec.ts

import { expect, test, type Page } from "@playwright/test"

async function signIn(page: Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
}

test("edits, validates, persists, previews, and remounts one self-hosted CKEditor instance", async ({ page }) => {
  const browserErrors: string[] = []
  page.on("pageerror", (error) => browserErrors.push(error.message))
  await signIn(page)

  await page.goto("/admin/ckeditor_articles")
  const row = page.getByRole("row").filter({ hasText: "CKEditor editing stays Rails-owned" })
  await row.getByRole("link", { name: "Edit" }).click()

  await expect(page.locator(".ck-editor")).toHaveCount(1)
  await expect(page.getByRole("button", { name: /Bold/ })).toBeVisible()
  const editable = page.locator(".ck-editor__editable")
  await expect(editable.getByRole("heading", { name: "Focused editing, explicit authority" })).toBeVisible()
  await expect(editable.getByText("The editor improves authoring; Rails decides what survives.")).toBeVisible()

  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/ckeditor-editor.png" })
  }

  await page.getByLabel("Title").fill("")
  await editable.evaluate((body) => {
    const range = document.createRange()
    range.selectNodeContents(body)
    range.collapse(false)
    const selection = window.getSelection()
    selection?.removeAllRanges()
    selection?.addRange(range)
    ;(body as HTMLElement).focus()
  })
  await page.keyboard.press("Enter")
  await page.keyboard.type("Validation preserves this CKEditor draft.")
  await page.getByRole("button", { name: "Update CKEditor Article" }).click()

  await expect(page.getByText("can't be blank")).toBeVisible()
  await expect(page.locator(".ck-editor")).toHaveCount(1)
  await expect(page.locator(".ck-editor__editable")).toContainText("Validation preserves this CKEditor draft.")

  await page.getByLabel("Title").fill("CKEditor editing stays Rails-owned")
  await page.getByRole("button", { name: "Update CKEditor Article" }).click()
  await expect(page).toHaveURL(/\/admin\/ckeditor_articles\/\d+$/)
  await expect(page.getByTestId("ckeditor-preview")).toContainText("Validation preserves this CKEditor draft.")

  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/ckeditor-preview.png" })
  }

  await page.getByRole("link", { name: "Edit CKEditor Article" }).click()
  await expect(page.locator(".ck-editor")).toHaveCount(1)
  await page.getByRole("link", { name: "CKEditor 5" }).click()
  await expect(page.locator(".ck-editor")).toHaveCount(0)
  await row.getByRole("link", { name: "Edit" }).click()
  await expect(page.locator(".ck-editor")).toHaveCount(1)
  expect(browserErrors).toEqual([])
})

test("keeps keyboard access and a usable narrow dark editor", async ({ browser }) => {
  const context = await browser.newContext({ colorScheme: "dark", viewport: { height: 844, width: 390 } })
  const page = await context.newPage()
  await signIn(page)
  await page.goto("/admin/ckeditor_articles/new")

  const editable = page.locator(".ck-editor__editable")
  await expect(editable).toBeVisible()
  await editable.focus()
  await page.keyboard.type("Keyboard-authored draft")
  await expect(editable).toContainText("Keyboard-authored draft")
  await expect(page.getByRole("button", { name: /Bold/ })).toBeVisible()
  await expect(page.locator(".ck-toolbar")).toHaveCSS("overflow-x", "auto")
  await context.close()
})

test("keeps and submits a meaningful textarea when JavaScript is disabled", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()

  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await page.goto("/admin/ckeditor_articles/new")

  const textarea = page.locator("textarea#ckeditor_article_body_html")
  await expect(textarea).toBeVisible()
  await textarea.fill("<h2>No-JavaScript draft</h2><p>Rails still accepts and sanitizes this field.</p>")
  await page.getByLabel("Title").fill("No-JavaScript CKEditor article")
  await page.getByRole("button", { name: "Create CKEditor Article" }).click()

  await expect(page.getByTestId("ckeditor-preview")).toContainText("No-JavaScript draft")
  await context.close()
})
