// test/browser/activity_center.spec.ts

import { expect, test } from "@playwright/test"

test("filters, persists read state, deep-links, reconnects, and deduplicates live activity", async ({ page }) => {
  await page.setViewportSize({ height: 1000, width: 1440 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  const bell = page.getByTestId("notification-bell")
  await expect(bell).toHaveAccessibleName("Notifications, 2 unread")
  await bell.click()
  await expect(page).toHaveURL(/\/admin\/activity_center/)
  await expect(page.getByTestId("activity-center")).toBeVisible()
  await expect(page.getByTestId("activity-cable-status")).toHaveText("connected")

  const mention = page.locator("[data-notification-sequence]").filter({ hasText: "You were mentioned" })
  await expect(mention.getByRole("link", { name: "You were mentioned" })).toHaveAttribute(
    "href",
    "/admin/conversations/release-coordination#message-release-coordination-message-1"
  )

  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ path: "docs/screenshots/activity-center.png" })
    await page.screenshot({ fullPage: true, path: "docs/screenshots/noticed-mention-1440-light.png" })
    await page.setViewportSize({ height: 844, width: 390 })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    await page.screenshot({ fullPage: true, path: "docs/screenshots/noticed-mention-390-dark.png" })
    await page.setViewportSize({ height: 1000, width: 1440 })
    await page.locator("html").evaluate(element => element.classList.remove("dark"))
  }

  const trial = page.locator("[data-notification-sequence]").filter({ hasText: "Trial follow-up" })
  await trial.getByRole("button", { name: "Mark read" }).click()
  await expect(bell).toHaveAccessibleName("Notifications, 1 unread")
  await page.reload()
  await expect(page.locator("[data-notification-sequence]").filter({ hasText: "Trial follow-up" }).getByRole("button", { name: "Mark unread" })).toBeVisible()
  await expect(page.locator("[data-notification-sequence]").filter({ hasText: "You were mentioned" }).getByRole("button", { name: "Mark read" })).toBeVisible()
  await expect(bell).toHaveAccessibleName("Notifications, 1 unread")

  await page.getByLabel("Filter notifications").selectOption("operation")
  await expect(page.getByRole("link", { name: "Import completed" })).toBeVisible()
  await expect(page.getByText("Account review requested")).not.toBeVisible()
  await page.getByLabel("Filter notifications").selectOption("all")

  await page.getByTestId("reconnect-activity").click()
  await page.getByRole("button", { name: "Create demo notification" }).click()
  await expect(page.getByText("Live account activity")).toHaveCount(1)
  await expect(page.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 2 unread")
  await expect(page.getByTestId("activity-cable-status")).toHaveText("connected")
  await page.reload()
  await expect(page.getByText("Live account activity")).toHaveCount(1)
  await expect(page.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 2 unread")

  await page.getByRole("link", { name: "Account review requested" }).click()
  await expect(page).toHaveURL(/\/admin\/accounts/)
})
