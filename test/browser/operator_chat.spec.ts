// test/browser/operator_chat.spec.ts

import { expect, test } from "@playwright/test"

test("persists, streams, reconnects, replays, and resets a synthetic operator conversation", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/operator_chat")

  await expect(page.getByTestId("operator-chat")).toBeVisible()
  await expect(page.getByTestId("chat-cable-status")).toHaveText("connected")
  await expect(page.getByText("Maya Ortiz")).toBeVisible()

  await page.getByLabel("Message as authenticated operator").fill("Browser-backed handoff")
  await page.getByRole("button", { name: "Send message" }).click()
  const postedMessage = page.locator("[data-message-sequence]").filter({ hasText: "Browser-backed handoff" })
  await expect(postedMessage).toBeVisible()
  await expect(postedMessage.getByText("You", { exact: true })).toBeVisible()

  await page.getByTestId("reconnect-chat").click()
  await expect(page.getByTestId("chat-cable-status")).toHaveText("disconnected")
  await page.evaluate(async () => {
    const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
    const response = await fetch("/admin/operator-chat/support-operations/messages", {
      method: "POST",
      credentials: "same-origin",
      headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ body: "Replayed after reconnect" })
    })
    if (!response.ok) throw new Error(`Offline command failed: ${response.status}`)
  })
  await expect(page.getByTestId("chat-cable-status")).toHaveText("connected")
  await expect(page.getByText("Browser-backed handoff")).toHaveCount(1)
  await expect(page.getByText("Replayed after reconnect")).toBeVisible()

  await page.reload()
  await expect(page.locator("[data-message-sequence]").filter({ hasText: "Browser-backed handoff" }).getByText("You", { exact: true })).toBeVisible()
  await page.getByRole("button", { name: "Reset synthetic conversation" }).click()
  await expect(page.getByText("Browser-backed handoff")).not.toBeVisible()
  await expect(page.getByText("The synthetic Northwind import is ready for review.")).toBeVisible()
})
