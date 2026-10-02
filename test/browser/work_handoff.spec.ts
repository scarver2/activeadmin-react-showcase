// test/browser/work_handoff.spec.ts

import { expect, test } from "@playwright/test"

for (const javaScriptEnabled of [true, false]) {
  test.describe(`work handoff JavaScript=${javaScriptEnabled}`, () => {
    test.use({ javaScriptEnabled })
    test("hands work to an agent, requires approval, and supports intervention", async ({ page }) => {
      await page.goto("/admin/login")
      await page.getByLabel("Email").fill("admin@example.test")
      await page.getByLabel("Password").fill("showcase-password")
      await page.getByRole("button", { name: "Sign In" }).click()
      await expect(page).toHaveURL(/\/admin(?:\/)?$/)
      await page.goto("/admin/work_handoff")
      await page.getByRole("button", { name: "Create synthetic work item" }).click()
      await page.getByRole("button", { name: "Assign to demo agent" }).click()
      await expect(page.getByText("State: agent · Progress: 0%", { exact: false })).toBeVisible()
      for (const progress of [25, 50, 75]) {
        await page.getByRole("button", { name: "Simulate next agent step" }).click()
        await expect(page.getByText(`State: ${progress === 75 ? "approval" : "agent"} · Progress: ${progress}%`, { exact: false })).toBeVisible()
      }
      await expect(page.getByRole("button", { name: "Simulate next agent step" })).toHaveCount(0)
      await expect(page.getByText("Human approval required; automated evidence is not authorization.")).toBeVisible()
      if (javaScriptEnabled) {
        await page.screenshot({ path: "docs/screenshots/work-handoff-approval.png", fullPage: true })
      }
      await page.getByRole("button", { name: "Take back to human" }).click()
      await expect(page.getByText("Human intervened and reclaimed the work.", { exact: false })).toBeVisible()
      await page.getByRole("button", { name: "Assign to demo agent" }).click()
      await expect(page.getByText("State: agent · Progress: 0%", { exact: false })).toBeVisible()
      for (const progress of [25, 50, 75]) {
        await page.getByRole("button", { name: "Simulate next agent step" }).click()
        await expect(page.getByText(`Progress: ${progress}%`, { exact: false })).toBeVisible()
      }
      await page.getByRole("button", { name: "Approve completion" }).click()
      await expect(page.getByText("State: completed · Progress: 100%", { exact: false })).toBeVisible()
      await page.reload()
      await expect(page.getByText("Human approved the synthetic evidence", { exact: false })).toBeVisible()
      await page.getByRole("button", { name: "Create synthetic work item" }).click()
      await page.getByRole("button", { name: "Assign to demo agent" }).click()
      await expect(page.getByText("State: agent · Progress: 0%", { exact: false })).toBeVisible()
      await page.getByRole("button", { name: "Cancel work" }).click()
      await expect(page.getByText("State: cancelled", { exact: false })).toBeVisible()
      await expect(page.getByRole("button", { name: "Simulate next agent step" })).toHaveCount(0)
      if (javaScriptEnabled) {
        await page.setViewportSize({ width: 390, height: 844 })
        await page.reload()
        await page.evaluate(() => document.documentElement.classList.add("dark"))
        await expect(page.getByText("State: cancelled", { exact: false })).toBeVisible()
        await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
        await page.screenshot({ path: "docs/screenshots/work-handoff-narrow-dark.png", fullPage: true })
      }
    })
  })
}
