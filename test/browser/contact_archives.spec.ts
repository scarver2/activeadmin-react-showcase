// test/browser/contact_archives.spec.ts

import { expect, test } from "@playwright/test"

for (const javaScriptEnabled of [true, false]) {
  test.describe(`contact inspector JavaScript=${javaScriptEnabled}`, () => {
    test.use({ javaScriptEnabled })
    test("inspects synthetic contacts and downloads normalized data without importing", async ({ page }) => {
      await page.goto("/admin/login")
      await page.getByLabel("Email").fill("admin@example.test")
      await page.getByLabel("Password").fill("showcase-password")
      await page.getByRole("button", { name: "Sign In" }).click()
      await expect(page).toHaveURL(/\/admin\/?$/)
      await page.goto("/admin/contact_archives")
      await expect(page.getByRole("heading", { name: "ABBU Contact Archive Inspector" })).toBeVisible()
      await expect(page.getByText("Parser: Legacy plist · Contacts: 3 · Diagnostics: 0")).toBeVisible()
      await expect(page.getByRole("heading", { name: "Exact shared-value evidence" })).toBeVisible()
      await expect(page.getByText("Fictional fixture. <script>not executable</script>", { exact: false })).toBeVisible()
      const downloadPromise = page.waitForEvent("download")
      await page.getByRole("link", { name: "Download synthetic JSON" }).click()
      const download = await downloadPromise
      expect(download.suggestedFilename()).toBe("northstar-synthetic.json")
      if (javaScriptEnabled) {
        await page.evaluate(() => window.scrollTo(0, 0))
        if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/contact-archive-inspector.png" })
        await page.setViewportSize({ width: 390, height: 844 })
        await page.reload()
        await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
        await page.keyboard.press("Escape")
        await page.evaluate(() => document.documentElement.classList.add("dark"))
        await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
        if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: "docs/screenshots/contact-archive-inspector-narrow-dark.png" })
      }
    })
  })
}
