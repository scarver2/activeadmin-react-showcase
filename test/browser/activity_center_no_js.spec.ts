// test/browser/activity_center_no_js.spec.ts

import { expect, test } from "@playwright/test"

test.use({ javaScriptEnabled: false })

test("reads mention truth, changes durable state, and follows the canonical deep link without JavaScript", async ({ page }) => {
  await page.setViewportSize({ height: 1000, width: 1440 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()

  await page.getByRole("link", { name: "Activity Center" }).first().click()
  const mention = page.getByRole("listitem").filter({ hasText: "You were mentioned" })
  const deepLink = mention.getByRole("link", { name: "You were mentioned" })
  await expect(deepLink).toHaveAttribute(
    "href",
    "/admin/conversations/release-coordination#message-release-coordination-message-1"
  )

  await mention.getByRole("button", { name: "Mark read" }).click()
  await expect(page.getByText("Notification state updated.")).toBeVisible()
  await page.reload()
  const persisted = page.getByRole("listitem").filter({ hasText: "You were mentioned" })
  await expect(persisted.getByRole("button", { name: "Mark unread" })).toBeVisible()

  await persisted.getByRole("link", { name: "You were mentioned" }).click()
  await expect(page).toHaveURL(
    /\/admin\/conversations\/release-coordination#message-release-coordination-message-1$/
  )
  await expect(page.locator("#message-release-coordination-message-1")).toBeVisible()

  await page.goto("/admin/activity_center")
  await page.getByRole("listitem").filter({ hasText: "You were mentioned" })
    .getByRole("button", { name: "Mark unread" }).click()
  await page.reload()
  await expect(page.getByRole("listitem").filter({ hasText: "You were mentioned" })
    .getByRole("button", { name: "Mark read" })).toBeVisible()
})
