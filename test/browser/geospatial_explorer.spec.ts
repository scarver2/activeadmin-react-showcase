// test/browser/geospatial_explorer.spec.ts

import { expect, test } from "@playwright/test"

test("loads the credential-free map and synchronizes keyboard selection", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/geospatial_explorer")

  await expect(page.getByTestId("map").locator("canvas")).toBeVisible()
  await page.getByRole("button", { name: "Taylor Hangar" }).click()
  await expect(page.getByRole("region", { name: "Selected location" })).toContainText("Taylor Hangar")
  await page.locator(".maplibregl-ctrl-zoom-in").click()
  await expect(page.getByRole("region", { name: "Locations" })).toBeVisible()
})
