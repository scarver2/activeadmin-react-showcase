// test/browser/image_annotation.spec.ts

import { expect, test } from "@playwright/test"

test("places and persists a focal point with pointer and keyboard", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin$/)
  await page.goto("/admin/image_annotation_editor")
  const canvas = page.getByRole("img", { name: /Image focal point editor/ })
  const bounds = await canvas.boundingBox()
  if (!bounds) throw new Error("Annotation canvas was not rendered")
  await expect(page.getByLabel("focal x")).toHaveValue("0.5")
  await canvas.click({ position: { x: bounds.width * 0.25, y: bounds.height * 0.75 } })
  await expect(page.getByLabel("focal x")).toHaveValue(/0.25/)
  await canvas.press("ArrowRight")
  await page.getByRole("button", { name: "Save normalized metadata" }).click()
  await expect(page.getByText("Annotation saved.", { exact: true })).toBeVisible()
  await page.reload()
  await expect(page.getByLabel("focal x")).toHaveValue(/0.26/)
})
