// test/browser/spacecraft_viewer.spec.ts

import { expect, test } from "@playwright/test"

test("loads the local 3D model and persists accessible component configuration", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/spacecraft_viewer")
  const canvas = page.getByLabel("Interactive Odyssey spacecraft")
  await expect(canvas).toHaveAttribute("data-render-state", "ready")
  await page.getByRole("button", { name: "Port wing" }).click()
  await expect(page.getByRole("region", { name: "Selected component" })).toContainText("ODY-210-L")
  await page.getByRole("button", { name: "Top camera" }).click()
  await page.getByRole("button", { name: "Exploded view" }).click()
  await page.getByLabel("Finish").selectOption("ceramic")
  await page.reload()
  await expect(page.getByLabel("Finish")).toHaveValue("ceramic")
  await expect(page.getByRole("button", { name: "Port wing" })).toHaveAttribute("aria-pressed", "true")
})
