// test/browser/safe_terminal.spec.ts

import { expect, test } from "@playwright/test"

async function signIn(page: import("@playwright/test").Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/safe_terminal")
  await expect(page.getByTestId("safe-terminal")).toBeVisible()
}

test("runs a fixed command in real xterm and replays durable output after reconnect", async ({ page }) => {
  await signIn(page)
  await expect(page.locator(".xterm")).toBeVisible()
  await expect(page.getByTestId("terminal-cable-status")).toHaveText("connecting")

  await page.getByRole("button", { name: "Inspect showcase status" }).click()
  const execution = page.locator("[data-execution-id]").first()
  await expect(execution).toHaveAttribute("data-state", /queued|running/)
  await expect(page.getByTestId("terminal-cable-status")).toHaveText("connected")
  const sequenceBefore = Number(await execution.getAttribute("data-sequence"))

  await page.getByTestId("reconnect-terminal").click()
  await expect(page.getByTestId("terminal-cable-status")).toHaveText("disconnected")
  await page.waitForTimeout(1_300)
  await expect(execution).toHaveAttribute("data-state", /running|completed/)
  await expect(page.getByTestId("terminal-cable-status")).toHaveText("connected")
  await expect(execution).toHaveAttribute("data-state", "completed", { timeout: 15_000 })
  await expect.poll(async () => Number(await execution.getAttribute("data-sequence"))).toBe(6)
  expect(Number(await execution.getAttribute("data-sequence"))).toBeGreaterThan(sequenceBefore)
  await expect(page.locator(".xterm-rows")).toContainText("Rails application: ready")
  await expect(page.locator(".xterm-rows")).toContainText("Command completed successfully")

  await page.reload()
  await expect(page.locator("[data-execution-id]").first()).toHaveAttribute("data-state", "completed")
})

test("rejects arbitrary xterm input and cancels authenticated deterministic work", async ({ page }) => {
  await signIn(page)
  const textarea = page.locator(".xterm-helper-textarea")
  await textarea.focus()
  await page.keyboard.type("whoami")
  await page.keyboard.press("Enter")
  await expect(page.locator(".xterm-rows")).toContainText("Rejected locally: command is not allowlisted")

  await page.getByRole("button", { name: "Preview deployment plan" }).click()
  const execution = page.locator("[data-execution-id]").first()
  await expect(execution).toHaveAttribute("data-state", /queued|running/)
  await execution.getByRole("button", { name: "Cancel" }).click()
  await expect(execution).toHaveAttribute("data-state", "cancelled")
  const terminalSequence = await execution.getAttribute("data-sequence")
  await page.waitForTimeout(1_500)
  await expect(execution).toHaveAttribute("data-sequence", terminalSequence!)
  await expect(page.locator(".xterm-rows")).toContainText("Cancellation accepted")
})
