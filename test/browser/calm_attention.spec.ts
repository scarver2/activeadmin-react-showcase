// test/browser/calm_attention.spec.ts

import { expect, test } from "@playwright/test"

test("shows restrained attention groups across light, dark and narrow layouts", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin\/?$/)
  await page.goto("/admin/calm_attention?scenario=exceptions")
  const context = page.getByText("Supporting context", { exact: true }).first()
  await context.focus()
  await page.keyboard.press("Enter")
  await expect(page.getByText(/the deadline is deliberately fixed/)).toBeVisible()
  await expect(page.getByText("Synthetic routine completion", { exact: true })).not.toBeVisible()
  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: 900 })
    if (width < 640) {
      await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
      await page.keyboard.press("Escape")
      await expect(page.locator("#main-menu")).not.toBeInViewport()
    }
    for (const mode of ["light", "dark"]) {
      await page.locator("html").evaluate((element, dark) => element.classList.toggle("dark", dark), mode === "dark")
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
      if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) await page.screenshot({ path: `docs/screenshots/calm-attention-${width}-${mode}.png`, fullPage: true })
    }
  }
})

test.describe("canonical attention", () => {
  test.use({ javaScriptEnabled: false })
  test("switches scenarios and opens native disclosure without JavaScript", async ({ page }) => {
    await page.goto("/admin/login")
    await page.getByLabel("Email").fill("admin@example.test")
    await page.getByLabel("Password").fill("showcase-password")
    await page.getByRole("button", { name: "Sign In" }).click()
    await expect(page).toHaveURL(/\/admin\/?$/)
    await page.goto("/admin/calm_attention")
    await page.getByLabel("Attention scenario").selectOption("healthy")
    await page.getByRole("button", { name: "Show scenario" }).click()
    await expect(page.getByText("All clear", { exact: true })).toBeVisible()
    await page.getByLabel("Attention scenario").selectOption("exceptions")
    await page.getByRole("button", { name: "Show scenario" }).click()
    await page.getByText("For awareness", { exact: true }).click()
    await expect(page.getByText("Synthetic routine completion", { exact: true })).toBeVisible()
  })
})
