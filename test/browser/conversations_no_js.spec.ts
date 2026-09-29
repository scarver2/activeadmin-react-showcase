// test/browser/conversations_no_js.spec.ts

import { expect, test } from "@playwright/test"

test.use({ javaScriptEnabled: false })

test("uses the authenticated conversation inbox and mutations without JavaScript", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)

  await page.goto("/admin/conversations")
  await expect(page.getByRole("heading", { name: "Inbox" })).toBeVisible()
  await page.getByRole("link", { name: "Release coordination" }).click()
  await expect(page.getByText("The release candidate is ready for the final accessibility pass.")).toBeVisible()

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
  await page.locator("article").filter({ hasText: "The release candidate" })
    .getByRole("button", { name: "Mark unread from here" }).click()
  await expect(page.getByText("Unread position updated.")).toBeVisible()

  await page.locator("article").filter({ hasText: "Edited without JavaScript" })
    .getByRole("button", { name: "Withdraw message" }).click()
  await expect(page.getByText(MessageTombstone)).toBeVisible()
})

const MessageTombstone = "[withdrawn]"
