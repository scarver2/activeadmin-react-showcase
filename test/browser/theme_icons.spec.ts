// test/browser/theme_icons.spec.ts
import { expect, test } from "@playwright/test"

test("explores labelled, token-aware icons without changing dashboard navigation", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  const dashboard = page.locator(".master-workspace")
  await expect(dashboard).toBeVisible()
  await expect(dashboard.locator(".master-domain .showcase-icon")).toHaveCount(16)
  await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
  const home = page.locator("#main-menu a").filter({ hasText: "Showcase Home" })
  await expect(home).toHaveCount(1)
  await expect(home.locator("svg")).toHaveAttribute("aria-hidden", "true")
  await page.keyboard.press("Escape")
  const sprite = await page.request.get("/showcase-icons.svg")
  expect(sprite.status()).toBe(200)
  expect(sprite.headers()["content-type"]).toContain("image/svg+xml")
  for (const dark of [false, true]) {
    if (dark) await page.getByRole("button", { name: /Toggle dark mode/i }).click()
    await expect(page.locator("html")).toHaveClass(dark ? /dark/ : /^(?!.*\bdark\b)/)
    expect(await home.locator(".showcase-icon-landmark").evaluate((node) => getComputedStyle(node).display)).toBe("none")
    await expect(home.locator(".showcase-icon-default")).toHaveAttribute("href", "/showcase-icons.svg#heroicons-squares-2x2")
    await expect(page.getByRole("link", { name: "Explore accounts", exact: true })).toHaveAttribute("href", "/admin/data_explorer?composition=bluebonnet")
    if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
      await page.screenshot({ fullPage: true, path: `docs/screenshots/semantic-icons-bluebonnet-${dark ? "dark" : "light"}.png` })
    }
  }
  await page.getByRole("button", { name: /Toggle dark mode/i }).click()
  await page.locator("body").evaluate((node) => node.setAttribute("data-showcase-icon-family", "bluebonnet"))
  expect(await home.locator(".showcase-icon-landmark").evaluate((node) => getComputedStyle(node).display)).toBe("inline")
  expect(await home.locator(".showcase-icon-default").evaluate((node) => getComputedStyle(node).display)).toBe("none")
  await page.locator("body").evaluate((node) => node.removeAttribute("data-showcase-icon-family"))
  await page.getByRole("link", { name: "Explore accounts", exact: true }).focus()
  await expect(page.getByRole("link", { name: "Explore accounts", exact: true })).toBeFocused()
  await page.keyboard.press("Enter")
  await expect(page).toHaveURL(/\/admin\/data_explorer\?composition=bluebonnet$/)
})

test("keeps decorative navigation and shortcuts usable without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page.getByText("All dashboard workspaces remain available without JavaScript.")).toBeVisible()
  await expect(page.getByRole("link", { name: "Showcase Home", exact: true })).toBeVisible()
  await page.getByRole("link", { name: "Account Data Explorer", exact: true }).click()
  await expect(page).toHaveURL(/\/admin\/data_explorer$/)
  await context.close()
})
