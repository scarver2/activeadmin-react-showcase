// test/browser/activity_center.spec.ts

import { expect, test } from "@playwright/test"

test("filters actionable attention, persists state, synchronizes tabs, and recovers by reload", async ({ context, page }) => {
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
  const sibling = await context.newPage()
  await sibling.goto("/admin/activity_center")
  await expect(sibling.getByTestId("activity-cable-status")).toHaveText("connected")

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

  await page.getByLabel("Filter notifications").selectOption("fyi")
  await expect(page.getByRole("link", { name: "Import completed" })).toBeVisible()
  await page.getByLabel("Filter notifications").selectOption("all")

  await page.getByTestId("reconnect-activity").click()
  await page.getByRole("button", { name: "Create demo notification" }).click()
  const actionable = page.locator("[data-notification-sequence]")
    .filter({ hasText: "Workflow review requested" })
    .filter({ has: page.getByRole("button", { name: "Complete review" }) })
  await expect(actionable).toHaveCount(1)
  const siblingActionable = sibling.locator("[data-notification-sequence]")
    .filter({ hasText: "Workflow review requested" })
    .filter({ has: sibling.getByRole("button", { name: "Complete review" }) })
  await expect(siblingActionable).toHaveCount(1)
  await expect(actionable.getByText("Requires action")).toBeVisible()
  await expect(actionable.getByText("High priority")).toBeVisible()
  if (process.env.CAPTURE_ACTIONABLE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/actionable-notification-center-1440-light.png" })
    await page.setViewportSize({ height: 844, width: 390 })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await page.screenshot({ fullPage: true, path: "docs/screenshots/actionable-notification-center-390-dark.png" })
    await page.setViewportSize({ height: 1000, width: 1440 })
    await page.locator("html").evaluate(element => element.classList.remove("dark"))
  }
  await expect(page.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 2 unread")
  await expect(page.getByTestId("activity-cable-status")).toHaveText("connected")
  // Deliver the real Rails broadcast before releasing the HTTP response, making
  // the duplicate-count race deterministic without mocking notification truth.
  await page.route("**/notifications/*/action", async route => {
    const response = await route.fetch()
    await expect(page.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 1 unread")
    await expect(sibling.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 1 unread")
    await route.fulfill({ response })
  })
  await actionable.getByRole("button", { name: "Complete review" }).click()
  await expect(actionable.getByRole("button", { name: "Complete review" })).not.toBeVisible()
  await expect(siblingActionable.getByRole("button", { name: "Complete review" })).not.toBeVisible()
  await expect(page.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 1 unread")
  await page.reload()
  await expect(page.getByText("Workflow review requested").first()).toBeVisible()
  await expect(page.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 1 unread")

  const trialAfterReload = page.locator("[data-notification-sequence]").filter({ hasText: "Trial follow-up" })
  await trialAfterReload.getByRole("button", { name: "Mark unread" }).click()
  await trialAfterReload.getByRole("button", { name: "Snooze for one hour" }).click()
  await expect(page.getByTestId("notification-bell")).toHaveAccessibleName("Notifications, 1 unread")
  await page.getByLabel("Filter notifications").selectOption("snoozed")
  await expect(page.getByText("Trial follow-up")).toBeVisible()
  await page.reload()
  await page.getByLabel("Filter notifications").selectOption("snoozed")
  await expect(page.getByText("Trial follow-up")).toBeVisible()
  await page.locator("[data-notification-sequence]").filter({ hasText: "Trial follow-up" })
    .getByRole("button", { name: "Restore" }).click()
  await page.getByLabel("Filter notifications").selectOption("all")
  await page.locator("[data-notification-sequence]").filter({ hasText: "Trial follow-up" })
    .getByRole("button", { name: "Dismiss" }).click()
  await page.getByLabel("Filter notifications").selectOption("dismissed")
  await expect(page.getByText("Trial follow-up")).toBeVisible()

  await page.getByLabel("Filter notifications").selectOption("fyi")
  await page.getByRole("link", { name: "Account review requested" }).click()
  await expect(page).toHaveURL(/\/admin\/accounts/)
  await sibling.close()
})
