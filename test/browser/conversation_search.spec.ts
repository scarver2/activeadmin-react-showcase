// test/browser/conversation_search.spec.ts

import { expect, test } from "@playwright/test"

test.use({ javaScriptEnabled: false })

test("searches only the authenticated conversation workspace without JavaScript", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()

  await page.goto("/admin/conversations")
  await page.getByRole("searchbox", { name: "Search conversations" }).fill("final accessibility pass")
  await page.getByRole("button", { name: "Search" }).click()

  await expect(page).toHaveURL(/\/admin\/conversations\/search\?q=final\+accessibility\+pass/)
  await expect(page.getByRole("heading", { level: 2, name: "Search conversations" })).toBeVisible()
  await expect(page.getByText("The release candidate is ready for the final accessibility pass.")).toBeVisible()
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)

  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-search-1440-light.png" })
    await page.setViewportSize({ width: 390, height: 844 })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await expect(page.locator("#main-menu")).not.toBeInViewport()
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-search-390-dark.png" })
  }

  await page.getByRole("link", { name: "Release coordination" }).click()
  await expect(page).toHaveURL(/\/admin\/conversations\/release-coordination\?before=\d+#message-/)
  await expect(page.getByText("The release candidate is ready for the final accessibility pass.")).toBeVisible()
})
