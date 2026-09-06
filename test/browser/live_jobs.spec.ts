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

test("streams progress and replays missed events after a real Cable reconnect", async ({ page }) => {
  await signIn(page)
  await page.getByRole("button", { name: "Run successful job" }).click()
  const operation = page.locator("[data-operation-id]").first()
  await expect(operation).toHaveAttribute("data-state", /queued|running/)
  await expect(page.getByTestId("cable-status")).toHaveText("connected")

  const sequenceBefore = Number((await operation.getByText(/event \d+/).textContent())?.match(/event (\d+)/)?.[1])
  const operationId = await operation.getAttribute("data-operation-id")
  if (!operationId) throw new Error("Operation id was not rendered")

  await page.getByTestId("reconnect-cable").click()
  await expect(page.getByTestId("cable-status")).toHaveText("disconnected")
  let offlineSequence = sequenceBefore
  await expect.poll(async () => {
    offlineSequence = await page.evaluate(async (id) => {
      const response = await fetch(`/admin/operations/${id}`, { headers: { Accept: "application/json" } })
      return (await response.json()).sequence as number
    }, operationId)
    return offlineSequence
  }, { timeout: 2_500 }).toBeGreaterThan(sequenceBefore)
  await expect(page.getByTestId("cable-status")).toHaveText("disconnected")
  await expect(page.getByTestId("cable-status")).toHaveText("connected")
  await expect(operation).toHaveAttribute("data-state", "completed", { timeout: 15_000 })
  const sequenceAfter = Number((await operation.getByText(/event \d+/).textContent())?.match(/event (\d+)/)?.[1])

  expect(sequenceAfter).toBeGreaterThan(sequenceBefore)
  const applied = (await operation.getAttribute("data-applied-sequences"))?.split(",").map(Number) || []
  const missedWhileOffline = Array.from({ length: offlineSequence - sequenceBefore }, (_, index) => sequenceBefore + index + 1)
  expect(applied).toEqual(expect.arrayContaining(missedWhileOffline))
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
