// test/browser/conversations_no_js.spec.ts

import { expect, test } from "@playwright/test"

test.use({ javaScriptEnabled: false })

test("uses the authenticated conversation inbox and mutations without JavaScript", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)

  await page.goto("/admin/conversations")
  await expect(page.getByRole("heading", { name: "Inbox" })).toBeVisible()
  await page.getByRole("link", { name: "Release coordination" }).click()
  for (let pageNumber = 0; pageNumber < 10 && await page.getByText("The release candidate is ready for the final accessibility pass.").count() === 0; pageNumber += 1) {
    const older = page.getByRole("link", { name: "Load 50 older messages" })
    if (await older.count() === 0) break
    await older.click()
  }
  await expect(page.getByText("The release candidate is ready for the final accessibility pass.")).toBeVisible()

  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversations-no-js-1440-light.png" })
    await page.setViewportSize({ width: 390, height: 844 })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await expect(page.locator("#main-menu")).not.toBeInViewport()
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversations-no-js-390-dark.png" })
  }

  await page.getByLabel("Message", { exact: true }).fill("No-JavaScript handoff ✅\nSecond line")
  await page.getByRole("button", { name: "Send message" }).click()
  const sent = page.locator("article").filter({ hasText: "No-JavaScript handoff" })
  await expect(sent).toContainText("Second line")

  await sent.getByRole("link", { name: "Edit message" }).click()
  await page.getByLabel("Message text").fill("Edited without JavaScript ✅")
  await page.getByRole("button", { name: "Save message" }).click()
  const edited = page.locator("article").filter({ hasText: "Edited without JavaScript" })
  await expect(edited).toContainText("edited")

  await edited.getByRole("button", { name: "Mark read through here" }).click()
  await expect(page.getByText("Read position updated.")).toBeVisible()
  await edited.getByRole("button", { name: "Mark unread from here" }).click()
  await expect(page.getByText("Unread position updated.")).toBeVisible()

  await page.locator("article").filter({ hasText: "Edited without JavaScript" })
    .getByRole("button", { name: "Withdraw message" }).click()
  await expect(page.getByText(MessageTombstone)).toBeVisible()
})

const MessageTombstone = "[withdrawn]"
