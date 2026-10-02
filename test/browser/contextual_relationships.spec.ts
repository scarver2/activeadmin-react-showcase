// test/browser/contextual_relationships.spec.ts

import { expect, test } from "@playwright/test"

for (const javaScriptEnabled of [true, false]) {
  test.describe(`contextual relationships JavaScript=${javaScriptEnabled}`, () => {
    test.use({ javaScriptEnabled })
    test("expands bounded context and opens canonical sources", async ({ page }) => {
      await page.goto("/admin/login")
      await page.getByLabel("Email").fill("admin@example.test")
      await page.getByLabel("Password").fill("showcase-password")
      await page.getByRole("button", { name: "Sign In" }).click()
      await expect(page).toHaveURL(/\/admin(?:\/)?$/)
      await page.goto("/admin/contextual_relationships")
      await expect(page).toHaveTitle(/Contextual Relationship Explorer/)
      await expect(page.getByRole("heading", { name: "Records", exact: true })).toBeVisible()
      await expect(page.getByText("packing-checklist.txt", { exact: true })).toHaveCount(0)
      await page.getByLabel("Relationship depth").selectOption("3")
      await page.getByRole("button", { name: "Expand context" }).click()
      if (javaScriptEnabled) {
        await page.getByRole("button", { name: "File: packing-checklist.txt" }).focus()
        await page.keyboard.press("Enter")
        await expect(page.getByRole("region", { name: "Selected context" })).toContainText("Synthetic checklist metadata")
        await page.getByRole("link", { name: "Open source record" }).click()
      } else {
        await page.getByRole("link", { name: "packing-checklist.txt", exact: true }).click()
      }
      await expect(page).toHaveURL(/source=file/)
      await expect(page.getByRole("heading", { name: "packing-checklist.txt", exact: true })).toBeVisible()
      await page.getByRole("link", { name: "Explore relationships from here" }).click()
      await expect(page).toHaveURL(/root=file/)
      if (javaScriptEnabled) {
        await page.setViewportSize({ width: 390, height: 844 })
        await page.goto("/admin/contextual_relationships?root=file")
        await page.evaluate(() => document.documentElement.classList.add("dark"))
        await expect(page.getByTestId("contextual-relationships")).toBeVisible()
        await expect(page.getByRole("heading", { name: "Records", exact: true })).toBeVisible()
        await page.screenshot({ path: "docs/screenshots/contextual-relationships-narrow-dark.png", fullPage: true })
        await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
        await page.setViewportSize({ width: 1440, height: 1000 })
        await page.goto("/admin/contextual_relationships?depth=3")
        await expect(page.getByTestId("contextual-relationships")).toBeVisible()
        await page.screenshot({ path: "docs/screenshots/contextual-relationships-desktop.png", fullPage: true })
      }
    })
  })
}
