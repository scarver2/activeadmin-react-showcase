// test/browser/file_image_manager.spec.ts

import { expect, test } from "@playwright/test"

test("uploads, previews, deletes, and resets Active Storage assets", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/file_image_manager")

  await expect(page.getByTestId("file-image-manager")).toBeVisible()
  const preview = page.getByAltText("Bluebonnet product sample preview")
  await expect(preview).toBeVisible()
  await expect.poll(() => preview.evaluate((image: HTMLImageElement) => image.naturalWidth)).toBeGreaterThan(0)
  await page.getByLabel("Title").fill("Browser upload")
  await page.getByLabel("File").setInputFiles({ name: "browser.txt", mimeType: "text/plain", buffer: Buffer.from("Synthetic browser fixture") })
  await expect(page.getByTestId("selected-file")).toContainText("browser.txt")
  await page.getByRole("button", { name: "Upload asset" }).click()
  await expect(page.getByText("Browser upload", { exact: true })).toBeVisible()

  await page.reload()
  await expect(page.getByText("Browser upload", { exact: true })).toBeVisible()
  await page.getByRole("button", { name: "Delete Browser upload" }).click()
  await expect(page.getByText("Browser upload", { exact: true })).not.toBeVisible()

  await page.getByRole("button", { name: "Delete Bluebonnet product sample" }).click()
  await expect(page.getByAltText("Bluebonnet product sample preview")).not.toBeVisible()
  await page.getByRole("button", { name: "Reset synthetic assets" }).click()
  await expect(page.getByAltText("Bluebonnet product sample preview")).toBeVisible()
})
