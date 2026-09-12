// test/browser/agent_console.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/agent_console")
  await expect(page.getByTestId("agent-console")).toBeVisible()
}

function observeResumeCursors(page: import("@playwright/test").Page) {
  const cursors: Array<{ runId: string, sequence: number }> = []
  page.on("websocket", (socket) => socket.on("framesent", ({ payload }) => {
    try {
      const command = JSON.parse(payload.toString())
      if (command.command !== "message") return
      const identifier = JSON.parse(command.identifier)
      const data = JSON.parse(command.data)
      if (identifier.channel === "AgentRunsChannel" && data.action === "resume") {
        cursors.push({ runId: identifier.run_id, sequence: data.after_sequence })
      }
    } catch {
      return
    }
  }))
  return cursors
}

test("streams deterministic activity, citation, result, and replays after reconnect", async ({ page }) => {
  const resumeCursors = observeResumeCursors(page)
  await signIn(page)
  await page.getByLabel("Prompt").fill("Which accounts need attention?")
  await page.getByRole("button", { name: "Run demo agent" }).click()
  const run = page.locator("[data-agent-run-id]").first()
  await expect(run).toHaveAttribute("data-state", /queued|running/)
  await expect(page.getByTestId("agent-cable-status")).toHaveText("connected")
  const runId = await run.getAttribute("data-agent-run-id")
  if (!runId) throw new Error("Agent run id was not rendered")
  const sequenceBefore = Number(await run.getAttribute("data-last-sequence"))
  await page.getByTestId("agent-reconnect").click()
  await expect(page.getByTestId("agent-cable-status")).toHaveText("disconnected")
  await expect.poll(async () => page.evaluate(async (id) => {
    const response = await fetch(`/admin/agent_runs/${id}`, { headers: { Accept: "application/json" } })
    const payload = await response.json()
    return payload.events.at(-1)?.sequence || 0
  }, runId)).toBeGreaterThan(sequenceBefore)
  await expect(run).toHaveAttribute("data-state", "completed", { timeout: 15_000 })
  await expect.poll(() => resumeCursors.some((cursor) => cursor.runId === runId && cursor.sequence === sequenceBefore)).toBe(true)
  await expect(run.getByRole("link", { name: "Authorized account dataset" })).toBeVisible()
  await expect(run).toContainText("Review trial accounts")
  const sequence = Number(await run.getAttribute("data-last-sequence"))
  expect(sequence).toBeGreaterThan(2)
  await page.reload()
  await expect(page.locator(`[data-agent-run-id="${runId}"][data-last-sequence="${sequence}"]`)).toBeVisible()
})

test("cancels deterministic work", async ({ page }) => {
  await signIn(page)
  await page.getByRole("button", { name: "Run demo agent" }).click()
  const run = page.locator("[data-agent-run-id]").first()
  await run.getByRole("button", { name: "Cancel" }).click()
  await expect(run).toHaveAttribute("data-state", "cancelled", { timeout: 15_000 })
})
