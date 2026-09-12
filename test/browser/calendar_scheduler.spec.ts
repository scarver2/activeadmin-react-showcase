// test/browser/calendar_scheduler.spec.ts

import { expect, test } from "@playwright/test"

test("creates, keyboard-reschedules, and drags a Rails-owned calendar event", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/calendar_scheduler")

  await expect(page.getByTestId("full-calendar")).toBeVisible()
  await expect(page.getByRole("button", { exact: true, name: "month" })).toBeVisible()
  await expect(page.getByRole("button", { exact: true, name: "week" })).toBeVisible()
  await expect(page.getByRole("button", { exact: true, name: "day" })).toBeVisible()

  const today = new Date().toISOString().slice(0, 10)
  const title = `Browser planning ${Date.now()}`
  await page.getByRole("button", { name: "Create event" }).click()
  await page.getByLabel("Title").fill(title)
  await page.getByLabel("Time zone").selectOption("UTC")
  await page.getByLabel("Starts").fill(`${today}T15:00`)
  await page.getByLabel("Ends").fill(`${today}T16:00`)
  await page.getByLabel("Location").fill("Playwright room")
  await page.getByRole("button", { name: "Save event" }).click()

  const event = page.locator(".fc-event").filter({ hasText: title })
  await expect(event).toBeVisible()
  await event.click()
  await expect(page.getByRole("region", { name: "Selected event" })).toContainText("Playwright room")

  const initialTime = await event.locator(".fc-event-time").textContent()
  await page.getByRole("button", { name: "Move one hour later" }).click()
  await expect.poll(async () => event.locator(".fc-event-time").textContent()).not.toBe(initialTime)

  const keyboardTime = await event.locator(".fc-event-time").textContent()
  const targetSlot = page.locator('.fc-timegrid-slot-lane[data-time="18:00:00"]')
  await targetSlot.scrollIntoViewIfNeeded()
  const eventBox = await event.boundingBox()
  const targetBox = await targetSlot.boundingBox()
  if (!eventBox || !targetBox) throw new Error("Expected rendered event and time-slot boxes")
  await page.mouse.move(eventBox.x + eventBox.width / 2, eventBox.y + eventBox.height / 2)
  await page.mouse.down()
  await page.mouse.move(eventBox.x + eventBox.width / 2, targetBox.y + targetBox.height / 2, { steps: 20 })
  await page.mouse.up()
  await expect.poll(async () => event.locator(".fc-event-time").textContent()).not.toBe(keyboardTime)

  const persistedTime = await event.locator(".fc-event-time").textContent()
  await page.reload()
  const persisted = page.locator(".fc-event").filter({ hasText: title })
  await expect(persisted).toBeVisible()
  await expect(persisted.locator(".fc-event-time")).toHaveText(persistedTime || "")
})

test("rejects an overlapping schedule proposal and restores the calendar", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/calendar_scheduler")

  const today = new Date().toISOString().slice(0, 10)
  const blockerTitle = `Conflict blocker ${Date.now()}`
  await page.getByRole("button", { name: "Create event" }).click()
  await page.getByLabel("Title").fill(blockerTitle)
  await page.getByLabel("Time zone").selectOption("UTC")
  await page.getByLabel("Starts").fill(`${today}T20:00`)
  await page.getByLabel("Ends").fill(`${today}T21:00`)
  await page.getByRole("button", { name: "Save event" }).click()
  await expect(page.locator(".fc-event").filter({ hasText: blockerTitle })).toBeVisible()

  await page.getByRole("button", { name: "Create event" }).click()
  await page.getByLabel("Title").fill(`Overlap ${Date.now()}`)
  await page.getByLabel("Time zone").selectOption("UTC")
  await page.getByLabel("Starts").fill(`${today}T20:30`)
  await page.getByLabel("Ends").fill(`${today}T21:30`)
  await page.getByRole("button", { name: "Save event" }).click()

  await expect(page.getByRole("alert")).toContainText(`overlaps ${blockerTitle}`)
  await expect(page.getByLabel("Create scheduled event")).toBeVisible()
})
