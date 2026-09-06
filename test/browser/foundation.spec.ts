// test/browser/foundation.spec.ts

import { expect, test } from "@playwright/test"

test("mounts the activeadmin-react proof island in Chromium", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()

  await expect(page).toHaveURL(/\/admin/)
  await expect(page.getByTestId("foundation-status")).toContainText("React island mounted")
  await expect(page.getByTestId("foundation-status")).toContainText("6")
  await expect(page.getByRole("heading", { name: "Showcase Home" })).toBeVisible()
})
