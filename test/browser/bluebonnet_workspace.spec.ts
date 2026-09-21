// test/browser/bluebonnet_workspace.spec.ts

import { expect, test } from "@playwright/test"

for (const width of [1440, 390]) {
  for (const mode of ["light", "dark"]) {
    test(`Bluebonnet workspace ${width} ${mode}`, async ({ page }) => {
      await page.setViewportSize({ width, height: 1000 })
      await page.emulateMedia({ colorScheme: mode as "light" | "dark" })
      await page.goto("/admin/login")
      await page.getByLabel("Email").fill("admin@example.test")
      await page.getByLabel("Password").fill("showcase-password")
      await page.getByRole("button", { name: "Sign In" }).click()
      await expect(page).toHaveURL(/\/admin\/?$/)
      await page.goto("/admin/data_explorer?composition=bluebonnet")
      await expect(page.getByRole("heading", { name: "Account intelligence." })).toBeVisible()
      await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")
      await page.locator("html").evaluate((html, dark) => html.classList.toggle("dark", dark), mode === "dark")
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
      await expect(page.getByRole("combobox", { name: "Rows", exact: true })).toHaveAttribute("title", "Rows")
      await expect(page.locator(".account-explorer-rows-label")).toHaveCSS("clip-path", "inset(50%)")
      const results = page.getByTestId("account-explorer-results")
      expect(await results.locator("thead").evaluate((element) => getComputedStyle(element).backgroundColor)).toBe(await results.evaluate((element) => getComputedStyle(element).backgroundColor))
      if (width > 640) {
        expect((await results.locator("thead").boundingBox())!.height).toBeLessThan(45)
        expect((await page.getByRole("navigation", { name: "Account pages" }).boundingBox())!.height).toBeLessThan(50)
      } else {
        expect((await page.getByRole("combobox", { name: "Rows", exact: true }).boundingBox())!.height).toBeGreaterThanOrEqual(44)
      }
      if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
        await page.screenshot({ fullPage: true, path: `docs/screenshots/bluebonnet-workspace-${width}-${mode}.png` })
      }
      await page.getByLabel("Search name").fill("Bluebonnet")
      await page.getByRole("button", { name: "Apply filters" }).click()
      await expect(page.getByTestId("account-explorer-results")).toContainText("1 account")
      await page.getByLabel("Search name").fill("")
      await page.getByRole("button", { name: "Apply filters" }).click()
      await expect(page.getByTestId("account-explorer-results")).toContainText("6 accounts")
      await page.getByRole("button", { name: "Next", exact: true }).click()
      await expect(page.getByRole("navigation", { name: "Account pages" })).toContainText("Page 2 of 2")
      await page.getByRole("button", { name: "Toggle main navigation menu" }).click()
      await expect(page.locator("#main-menu")).toBeInViewport()
      await page.keyboard.press("Escape")
      await expect(page.locator("#main-menu")).not.toBeInViewport()
    })
  }
}
