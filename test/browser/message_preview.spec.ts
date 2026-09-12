// test/browser/message_preview.spec.ts

import { expect, test } from "@playwright/test"

test("inspects sandboxed mail and bounded rich attachments", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin$/)
  await page.goto("/admin/message_preview_center")
  await expect(page.getByRole("heading", { name: /Your synthetic operations report/ })).toBeVisible()
  await page.getByRole("tab", { name: "Text" }).click()
  await expect(page.getByText("The synthetic report is ready.")).toBeVisible()
  await page.getByRole("button", { name: "Preview chart.png" }).click()
  await expect(page.getByAltText(/chart.png/)).toBeVisible()
  await page.getByRole("button", { name: "Preview report.pdf" }).click()
  await expect(page.getByTitle(/PDF preview/)).toBeVisible()
  await page.getByRole("button", { name: "Preview brief.docx" }).click()
  await expect(page.getByText(/downloaded rather than executed/)).toBeVisible()
})
