// test/browser/conversation_presence.spec.ts

import { expect, test } from "@playwright/test"
import type { Page } from "@playwright/test"

async function signIn(page: Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

test("keeps presence ephemeral and collapses independent tabs for one membership", async ({ browser }) => {
  const firstContext = await browser.newContext()
  const secondContext = await browser.newContext()
  const first = await firstContext.newPage()
  const second = await secondContext.newPage()

  try {
    await first.setViewportSize({ width: 1440, height: 1000 })
    await signIn(first)
    await signIn(second)
    await first.goto("/admin/conversations/release-coordination")
    await second.goto("/admin/conversations/release-coordination")

    await expect(first.getByRole("status")).toContainText("1 person online")
    await expect(second.getByRole("status")).toContainText("1 person online")

    await second.getByLabel("Message as You").fill("Typing stays ephemeral across tabs")
    await expect(first.getByRole("status")).not.toContainText("is typing")
    await secondContext.close()
    await expect(first.getByRole("status")).toContainText("1 person online")

    if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
      await first.screenshot({ fullPage: true, path: "docs/screenshots/conversation-presence-1440-light.png" })
      await first.setViewportSize({ width: 390, height: 844 })
      await first.reload()
      await expect(first.getByRole("status")).toContainText("1 person online")
      await first.locator("html").evaluate(element => element.classList.add("dark"))
      expect(await first.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
      await first.screenshot({ fullPage: true, path: "docs/screenshots/conversation-presence-390-dark.png" })
    }
  } finally {
    await firstContext.close()
    await secondContext.close().catch(() => undefined)
  }
})
