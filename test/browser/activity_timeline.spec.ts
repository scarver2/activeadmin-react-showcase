// test/browser/activity_timeline.spec.ts

import { expect, test } from "@playwright/test"

for (const javaScriptEnabled of [true, false]) {
  test.describe(`activity timeline JavaScript=${javaScriptEnabled}`, () => {
    test.use({ javaScriptEnabled })
    test("filters, resumes and inspects canonical synthetic sources", async ({ page }) => {
      await page.goto("/admin/login")
      await page.getByLabel("Email").fill("admin@example.test")
      await page.getByLabel("Password").fill("showcase-password")
      await page.getByRole("button", { name: "Sign In" }).click()
      await expect(page).toHaveURL(/\/admin\/?$/)
      await page.goto("/admin/activity_timeline")
      await expect(page).toHaveTitle(/Cross-Domain Activity Timeline/)
      await page.getByLabel("Event family", { exact: true }).selectOption("comment")
      await page.getByLabel("Group events by").selectOption("family")
      await page.getByRole("button", { name: "Apply timeline filters" }).click()
      await expect(page.getByRole("heading", { name: "Comments", exact: true })).toBeVisible()
      await expect(page.getByText("Source redacted — details unavailable", { exact: true })).toBeVisible()
      if (javaScriptEnabled) {
        const context = page.getByRole("button", { name: "Context for comment-0000", exact: true })
        await context.focus()
        await page.keyboard.press("Enter")
        await expect(context).toHaveAttribute("aria-expanded", "true")
        if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ path: "docs/screenshots/activity-timeline-desktop.png" })
        await page.setViewportSize({ width: 390, height: 844 })
        await page.locator("html").evaluate(element => element.classList.add("dark"))
        await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
        await page.keyboard.press("Escape")
        expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true)
        if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ path: "docs/screenshots/activity-timeline-narrow-dark.png" })
      }
      await page.getByRole("link", { name: "Older events", exact: true }).click()
      await expect(page.getByRole("link", { name: "Open source comment-0026", exact: true })).toBeVisible()
      await page.reload()
      await expect(page.getByRole("link", { name: "Open source comment-0026", exact: true })).toBeVisible()
      await page.getByRole("link", { name: "Open source comment-0026", exact: true }).click()
      await expect(page).toHaveURL(/source=comment-0026/)
      await expect(page.getByRole("heading", { name: "Comments source", exact: true })).toBeVisible()
      await expect(page.getByText("Use the reusable packing crates.", { exact: true })).toBeVisible()
      await page.goto("/admin/activity_timeline?cursor=invalid")
      await expect(page.getByRole("alert")).toContainText("Start again")
    })
  })
}
