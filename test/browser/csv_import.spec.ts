// test/browser/csv_import.spec.ts

import { expect, test } from "@playwright/test"

test("uploads, maps, confirms, processes, and recovers a bounded CSV import", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/csv_import_workflow")
  await page.getByLabel("Synthetic CSV file").setInputFiles({
    name: "browser-contacts.csv", mimeType: "text/csv",
    buffer: Buffer.from("given,family,mail,company\nKatherine,Johnson,katherine.browser@example.test,Bluebonnet Logistics\nInvalid,Person,not-an-email,Missing Account")
  })
  await page.getByRole("button", { name: "Upload and preview" }).click()
  await expect(page.getByText("Preview 2 rows")).toBeVisible()
  await expect(page).toHaveURL(/token=/)
  await page.getByLabel("Map given").selectOption("first_name")
  await page.getByLabel("Map family").selectOption("last_name")
  await page.getByLabel("Map mail").selectOption("email")
  await page.getByLabel("Map company").selectOption("account")
  page.once("dialog", (dialog) => dialog.accept())
  await page.getByRole("button", { name: "Confirm import" }).click()
  await expect(page.getByRole("heading", { name: "Import completed" })).toBeVisible({ timeout: 20_000 })
  await expect(page.getByText(/2\/2 processed · 1 imported · 1 failed/)).toBeVisible()
  await page.reload()
  await expect(page.getByRole("heading", { name: "Import completed" })).toBeVisible()
  await page.goto("/admin/contacts")
  await expect(page.getByText("katherine.browser@example.test")).toBeVisible()
})
