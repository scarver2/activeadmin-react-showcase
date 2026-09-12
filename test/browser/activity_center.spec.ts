// test/browser/activity_center.spec.ts

import { expect, test } from "@playwright/test"

test("filters, persists read state, deep-links, reconnects, and deduplicates live activity", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/activity_center")
  await expect(page.getByTestId("activity-center")).toBeVisible()
  await expect(page.getByTestId("activity-cable-status")).toHaveText("connected")

  const trial = page.locator("[data-notification-sequence]").filter({ hasText: "Trial follow-up" })
  await trial.getByRole("button", { name: "Mark read" }).click()
  await page.reload()
  await expect(page.locator("[data-notification-sequence]").filter({ hasText: "Trial follow-up" }).getByRole("button", { name: "Mark unread" })).toBeVisible()

  await page.getByLabel("Filter notifications").selectOption("operation")
  await expect(page.getByRole("link", { name: "Import completed" })).toBeVisible()
  await expect(page.getByText("Account review requested")).not.toBeVisible()
  await page.getByLabel("Filter notifications").selectOption("all")

  await page.getByTestId("reconnect-activity").click()
  await page.getByRole("button", { name: "Create demo notification" }).click()
  await expect(page.getByText("Live account activity")).toHaveCount(1)
  await expect(page.getByTestId("activity-cable-status")).toHaveText("connected")
  await page.reload()
  await expect(page.getByText("Live account activity")).toHaveCount(1)

  await page.getByRole("link", { name: "Account review requested" }).click()
  await expect(page).toHaveURL(/\/admin\/accounts/)
})
