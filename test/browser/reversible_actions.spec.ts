// test/browser/reversible_actions.spec.ts

import { expect, test } from "@playwright/test"

for (const javaScriptEnabled of [true, false]) {
  test.describe(`audited undo JavaScript=${javaScriptEnabled}`, () => {
    test.use({ javaScriptEnabled })
    test("changes and undoes through canonical forms", async ({ page }) => {
      await page.goto("/admin/login")
      await page.getByLabel("Email").fill("admin@example.test")
      await page.getByLabel("Password").fill("showcase-password")
      await page.getByRole("button", { name: "Sign In" }).click()
      await expect(page).toHaveURL(/\/admin\/?$/)
      await page.goto("/admin/reversible_actions")
      await page.getByRole("button", { name: /^Change region for/ }).first().click()
      await expect(page).toHaveURL(/receipt=\d+/)
      const receipt = page.locator('[id^="receipt_"]').first()
      await expect(receipt.getByRole("status")).toContainText("available")
      if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ fullPage: true, path: `docs/screenshots/reversible-actions-${javaScriptEnabled ? "enhanced" : "fallback"}.png` })
      await receipt.getByRole("button", { name: "Undo region change" }).focus()
      await page.keyboard.press("Enter")
      await expect(receipt.getByRole("status")).toContainText("already undone")
      await expect(receipt).toContainText("undo:")
    })
  })
}

test("server rejects a stale undo form after expiry", async ({ page }) => {
  test.setTimeout(70_000)
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
  await page.goto("/admin/reversible_actions")
  await page.getByRole("button", { name: /^Change region for/ }).first().click()
  await expect(page).toHaveURL(/receipt=\d+/)
  const receipt = page.locator('[id^="receipt_"]').first()
  await expect(receipt.getByRole("status")).toContainText("available")
  const expires = await receipt.getByRole("status").innerText()
  const deadline = Date.parse(expires.match(/Expires (.+)\./)![1])
  await expect.poll(() => Date.now(), { timeout: 40_000, intervals: [1000] }).toBeGreaterThan(deadline + 1000)
  await receipt.getByRole("button", { name: "Undo region change" }).click()
  await expect(page.getByText("Undo unavailable: expired")).toBeVisible()
  await expect(page.locator('[id^="receipt_"]').first().getByRole("status")).toContainText("expired")
})
