// test/browser/bulk_action_workbench.spec.ts

import { expect, test } from "@playwright/test"

for (const javaScriptEnabled of [true, false]) {
  test.describe(`bulk workbench JavaScript=${javaScriptEnabled}`, () => {
    test.use({ javaScriptEnabled })
    test("previews, confirms and recovers durable outcomes", async ({ page }) => {
      await page.goto("/admin/login")
      await page.getByLabel("Email").fill("admin@example.test")
      await page.getByLabel("Password").fill("showcase-password")
      await page.getByRole("button", { name: "Sign In" }).click()
      await expect(page).toHaveURL(/\/admin\/?$/)
      await page.goto("/admin/bulk_action_workbench")
      await page.getByRole("checkbox").first().check()
      await page.getByRole("checkbox").nth(1).check()
      await page.getByLabel("Target region").selectOption(javaScriptEnabled ? "East" : "West")
      await page.getByRole("button", { name: "Preview selected records" }).click()
      await expect(page).toHaveURL(/batch=\d+/)
      await expect(page.getByRole("button", { name: "Confirm region changes" })).toBeVisible()
      await page.getByRole("button", { name: "Confirm region changes" }).focus()
      await page.keyboard.press("Enter")
      if (javaScriptEnabled) {
        await expect(page.getByRole("region", { name: "Durable bulk progress" })).toContainText("completed: 100%", { timeout: 20_000 })
      } else {
        await expect.poll(async () => {
          await page.getByRole("link", { name: "Refresh canonical results" }).click()
          return page.getByRole("status").innerText()
        }, { timeout: 20_000 }).toContain("100%")
      }
      await page.getByRole("link", { name: "Refresh canonical results" }).click()
      await expect(page.getByRole("cell", { name: "updated", exact: true }).first()).toBeVisible()
      await expect(page.getByRole("button", { name: "Resume pending records" })).toHaveCount(0)
      if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ path: `docs/screenshots/bulk-workbench-${javaScriptEnabled ? "enhanced" : "fallback"}.png`, fullPage: true })
    })
  })
}
