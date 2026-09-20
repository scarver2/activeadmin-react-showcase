// test/browser/theme_icons.spec.ts
import { expect, test } from "@playwright/test"

test("explores labelled, token-aware icons without changing navigation or metrics", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  const metrics = page.getByTestId("foundation-status")
  await expect(metrics).toBeVisible()
  await expect(metrics.locator(".showcase-icon")).toHaveCount(3)
  const home = page.getByRole("link", { name: "Showcase Home", exact: true })
  await expect(home).toHaveCount(1)
  await expect(home.locator("svg")).toHaveAttribute("aria-hidden", "true")
  const sprite = await page.request.get("/showcase-icons.svg")
  expect(sprite.status()).toBe(200)
  expect(sprite.headers()["content-type"]).toContain("image/svg+xml")
  for (const theme of ["v3", "v3_texas"]) {
    await page.getByLabel("Color palette").selectOption(theme)
    await expect(page.locator(`[data-showcase-theme-marker="${theme}"]`)).toBeVisible()
    for (const dark of [false, true]) {
      if (dark) await page.getByRole("button", { name: /Toggle dark mode/i }).click()
      await expect(page.locator("html")).toHaveClass(dark ? /dark/ : /^(?!.*\bdark\b)/)
      expect(await home.locator(".showcase-icon-landmark").evaluate((node) => getComputedStyle(node).display)).toBe(theme === "v3_texas" ? "inline" : "none")
      await expect(page.getByRole("link", { name: "Browse accounts", exact: true })).toHaveAttribute("href", "/admin/accounts")
      if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
        await page.screenshot({ fullPage: true, path: `docs/screenshots/icons-${theme}-${dark ? "dark" : "light"}.png` })
      }
    }
    await page.getByRole("button", { name: /Toggle dark mode/i }).click()
  }
  await page.getByRole("link", { name: "Browse accounts", exact: true }).focus()
  await expect(page.getByRole("link", { name: "Browse accounts", exact: true })).toBeFocused()
  await page.keyboard.press("Enter")
  await expect(page).toHaveURL(/\/admin\/accounts$/)
})

test("keeps decorative navigation and shortcuts usable without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page.getByText("Showcase metrics remain available from the server while JavaScript loads.")).toBeVisible()
  await expect(page.getByRole("link", { name: "Showcase Home", exact: true })).toBeVisible()
  await page.getByRole("link", { name: "Browse accounts", exact: true }).click()
  await expect(page).toHaveURL(/\/admin\/accounts$/)
  await context.close()
})
