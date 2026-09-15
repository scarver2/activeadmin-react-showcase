// test/browser/material_sphere_studio.spec.ts

import { expect, test } from "@playwright/test"

test("renders and persists the glossy red material sphere in real Chromium", async ({ page }) => {
  await page.setViewportSize({ height: 1160, width: 1440 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/material_sphere_studio")
  const canvas = page.getByLabel("Interactive glossy red material sphere")
  await expect(canvas).toHaveAttribute("data-render-state", "ready")
  await page.getByRole("button", { name: "Front view" }).click()
  await expect(page.getByRole("region", { name: "Material recipe" })).toContainText("#d20a2e")
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/material-sphere-studio.png" })
  }
  await page.getByLabel("Red finish").selectOption("ruby-metal")
  await expect(page.getByRole("region", { name: "Material recipe" })).toContainText("0.72")
  await page.reload()
  await expect(page.getByLabel("Red finish")).toHaveValue("ruby-metal")
  await expect(canvas).toHaveAttribute("data-render-state", "ready")
})
