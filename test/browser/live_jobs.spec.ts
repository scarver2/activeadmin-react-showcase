// test/browser/live_jobs.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/live_jobs")
  await expect(page.getByTestId("operations-center")).toBeVisible()
}

function observeResumeCursors(page: import("@playwright/test").Page) {
  const cursors: Array<{ operationId: string, sequence: number }> = []
  page.on("websocket", (socket) => {
    socket.on("framesent", ({ payload }) => {
      try {
        const command = JSON.parse(payload.toString())
        if (command.command !== "message") return

        const identifier = JSON.parse(command.identifier)
        const data = JSON.parse(command.data)
        if (data.action === "resume") cursors.push({ operationId: identifier.operation_id, sequence: data.after_sequence })
      } catch {
        return
      }
    })
  })
  return cursors
}

test("streams progress and replays missed events after a real Cable reconnect", async ({ page }) => {
  const resumeCursors = observeResumeCursors(page)
  await signIn(page)
  await page.getByRole("button", { name: "Run successful job" }).click()
  const operation = page.locator("[data-operation-id]").first()
  await expect(operation).toHaveAttribute("data-state", /queued|running/)
  await expect(page.getByTestId("cable-status")).toHaveText("connected")

  const operationId = await operation.getAttribute("data-operation-id")
  if (!operationId) throw new Error("Operation id was not rendered")

  const reconnectCursorsBefore = resumeCursors.filter((cursor) => cursor.operationId === operationId).length
  await page.getByTestId("reconnect-cable").click()
  await expect(page.getByTestId("cable-status")).toHaveText("disconnected")
  await page.waitForTimeout(100)
  const appliedBeforeReconnect = (await operation.getAttribute("data-applied-sequences"))?.split(",").map(Number) || []
  const sequenceBefore = appliedBeforeReconnect.at(-1)!
  let offlineSequence = sequenceBefore
  await expect.poll(async () => {
    offlineSequence = await page.evaluate(async (id) => {
      const response = await fetch(`/admin/operations/${id}`, { headers: { Accept: "application/json" } })
      return (await response.json()).sequence as number
    }, operationId)
    return offlineSequence
  }, { timeout: 2_500 }).toBeGreaterThan(sequenceBefore)
  await expect(page.getByTestId("cable-status")).toHaveText("disconnected")
  await expect(operation).toHaveAttribute("data-state", "completed", { timeout: 15_000 })
  await expect.poll(() => resumeCursors.filter((cursor) => cursor.operationId === operationId).length)
    .toBeGreaterThan(reconnectCursorsBefore)
  const reconnectResumeCursors = resumeCursors
    .filter((cursor) => cursor.operationId === operationId)
    .slice(reconnectCursorsBefore)
    .map((cursor) => cursor.sequence)
  expect(reconnectResumeCursors[0]).toBe(sequenceBefore)
  expect(reconnectResumeCursors).toEqual([...reconnectResumeCursors].sort((left, right) => left - right))
  const sequenceAfter = Number((await operation.getByText(/event \d+/).textContent())?.match(/event (\d+)/)?.[1])

  expect(sequenceAfter).toBeGreaterThan(sequenceBefore)
  const applied = (await operation.getAttribute("data-applied-sequences"))?.split(",").map(Number) || []
  const missedWhileOffline = Array.from({ length: offlineSequence - sequenceBefore }, (_, index) => sequenceBefore + index + 1)
  expect(applied).toEqual(expect.arrayContaining(missedWhileOffline))
  expect(applied.filter((sequence) => sequence > sequenceBefore)).toEqual(
    Array.from({ length: sequenceAfter - sequenceBefore }, (_, index) => sequenceBefore + index + 1)
  )
  await expect(operation).toContainText("Six account summaries are ready")
})

test("cancels and retries through authenticated Rails commands", async ({ page }) => {
  await signIn(page)
  const initialCount = await page.locator("[data-operation-id]").count()
  await page.getByRole("button", { name: "Run successful job" }).click()
  const original = page.locator("[data-operation-id]").first()
  await original.getByRole("button", { name: "Cancel" }).click()
  await expect(original).toHaveAttribute("data-state", "cancelled", { timeout: 15_000 })

  await original.getByRole("button", { name: "Retry" }).click()
  await expect(page.locator("[data-operation-id]")).toHaveCount(initialCount + 2)
  await expect(page.locator("[data-operation-id]").first()).toHaveAttribute("data-state", "completed", { timeout: 15_000 })
})

test("shows an expected worker failure as a persistent terminal state", async ({ page }) => {
  await signIn(page)
  await page.getByRole("button", { name: "Run failing job" }).click()
  const operation = page.locator("[data-operation-id]").first()

  await expect(operation).toHaveAttribute("data-state", "failed", { timeout: 15_000 })
  await expect(operation).toContainText("Demonstration failure after safe cleanup")
})
