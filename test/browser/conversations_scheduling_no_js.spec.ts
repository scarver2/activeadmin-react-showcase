// test/browser/conversations_scheduling_no_js.spec.ts

import { expect, test } from "@playwright/test"

test.use({ javaScriptEnabled: false })

test("schedules and manages private conversation delivery without JavaScript", async ({ page }) => {
  await page.setViewportSize({ height: 1200, width: 1440 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await page.goto("/admin/conversations/release-coordination")
  await page.getByRole("link", { name: "Scheduled messages" }).click()

  await expect(page.getByText("Review the release health report tomorrow morning.")).toBeVisible()
  await expect(page.getByText("The scheduled release reminder arrived on time.")).toBeVisible()
  await expect(page.getByRole("heading", { name: "Recently delivered" })).toBeVisible()

  const scheduledFor = localDateTime(2)
  const sendLater = page.locator(".panel").filter({ has: page.getByRole("heading", { name: "Send later" }) })
  await sendLater.getByLabel("Message", { exact: true }).fill("Scheduled without JavaScript ✅")
  await sendLater.getByLabel("Send at").fill(scheduledFor)
  await sendLater.getByRole("button", { name: "Schedule message" }).click()
  await expect(page.getByText("Message scheduled.")).toBeVisible()
  await expect(page.getByText("Scheduled without JavaScript ✅")).toBeVisible()

  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.evaluate(() => window.scrollTo(0, 0))
    await page.screenshot({
      fullPage: true,
      path: "docs/screenshots/conversations-scheduled-1440-light.png"
    })
    await page.setViewportSize({ height: 844, width: 390 })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await page.evaluate(() => window.scrollTo(0, 0))
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    expect(await page.evaluate(() => window.scrollX)).toBe(0)
    await expectWithinViewport(page.getByRole("heading", { name: "Send later" }))
    await expectWithinViewport(page.getByLabel("Message", { exact: true }))
    await expectWithinViewport(page.getByRole("button", { name: "Schedule message" }))
    await expectWithinViewport(page.getByRole("heading", { name: "Pending delivery" }))
    await page.screenshot({
      fullPage: true,
      path: "docs/screenshots/conversations-scheduled-390-dark.png"
    })
  }

  const item = page.getByRole("listitem").filter({ hasText: "Scheduled without JavaScript" })
  await item.getByRole("link", { name: "Edit or reschedule" }).click()
  await page.getByLabel("Message").fill("Rescheduled without JavaScript ✅")
  await page.getByLabel("Send at").fill(localDateTime(3))
  await page.getByRole("button", { name: "Update scheduled message" }).click()
  await expect(page.getByText("Rescheduled without JavaScript ✅")).toBeVisible()

  await page.getByRole("listitem").filter({ hasText: "Rescheduled without JavaScript" })
    .getByRole("button", { name: "Cancel scheduled message" }).click()
  await expect(page.getByText("Scheduled message cancelled.")).toBeVisible()
  await expect(page.getByText("Rescheduled without JavaScript ✅")).toHaveCount(0)
})

function localDateTime(daysFromNow: number) {
  const value = new Date(Date.now() + daysFromNow * 24 * 60 * 60 * 1000)
  const local = new Date(value.getTime() - value.getTimezoneOffset() * 60 * 1000)
  return local.toISOString().slice(0, 16)
}

async function expectWithinViewport(locator: import("@playwright/test").Locator) {
  const box = await locator.boundingBox()
  expect(box).not.toBeNull()
  expect(box!.x).toBeGreaterThanOrEqual(0)
  expect(box!.x + box!.width).toBeLessThanOrEqual(390)
}
