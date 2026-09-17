// test/browser/geospatial_explorer.spec.ts

import { expect, test } from "@playwright/test"

test("loads the credential-free map and synchronizes keyboard selection", async ({ page }) => {
  await page.setViewportSize({ height: 1000, width: 1440 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/geospatial_explorer")

  await expect(page.getByTestId("map")).toHaveAttribute("data-ready", "true")
  await expect(page.getByTestId("map").locator("canvas")).toBeVisible()
  await expect(page.getByText("Anna, Texas · local points of interest")).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/geospatial-explorer.png" })
  }
  await page.getByRole("button", { name: "Sherley Heritage Park" }).click()
  await expect(page.getByRole("region", { name: "Selected location" })).toContainText("Sherley Heritage Park")
  await page.locator(".maplibregl-ctrl-zoom-in").click()
  await expect(page.getByRole("region", { name: "Locations" })).toBeVisible()
})
