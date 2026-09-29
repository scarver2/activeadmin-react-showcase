// test/browser/conversation_workspace.spec.ts

import { expect, test } from "@playwright/test"

test("enhances the durable conversation workflow at desktop and narrow widths", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)

  await page.goto("/admin/conversations/release-coordination")
  await expect(page.getByRole("region", { name: "Conversation workspace" })).toBeVisible()
  await expect(page.locator("[data-conversation-fallback='thread']")).toHaveCount(0)

  await page.evaluate(async () => {
    const csrf = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
    const endpoint = "/admin/conversations/release-coordination/messages.json"
    const current = await fetch(endpoint, { credentials: "same-origin", headers: { Accept: "application/json" } }).then(response => response.json())
    const needed = current.selected.olderCursor ? 0 : Math.max(0, 52 - current.selected.messages.length)
    for (let index = 0; index < needed; index += 1) {
      const response = await fetch(endpoint, {
        body: JSON.stringify({ message: { body: `Browser history fixture ${index + 1}` } }),
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrf },
        method: "POST"
      })
      if (!response.ok) throw new Error(`fixture message failed: ${response.status}`)
    }
  })
  await page.reload()
  await expect(page.getByRole("button", { name: "Load 50 older messages" })).toBeVisible()

  const list = page.getByRole("list", { name: "Messages" })
  const composer = page.getByLabel("Message as You")
  expect(await list.evaluate(element => element.scrollHeight > element.clientHeight)).toBe(true)
  await expect.poll(() => list.evaluate(element => element.scrollHeight - element.scrollTop - element.clientHeight)).toBeLessThanOrEqual(2)
  const desktopComposer = await composer.boundingBox()
  expect(desktopComposer && desktopComposer.y + desktopComposer.height <= 1000).toBe(true)
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)

  await composer.fill("Draft survives thread navigation ✅\nSecond line")
  await page.setViewportSize({ width: 390, height: 844 })
  await page.getByRole("button", { name: /Inbox/ }).click()
  await expect(page.getByRole("heading", { name: "Conversations" })).toBeFocused()
  await page.getByRole("link", { name: /Release coordination/ }).click()
  await expect(page.getByRole("region", { name: "Conversation workspace" }).getByRole("heading", { name: "Release coordination" })).toBeFocused()
  await expect(composer).toHaveValue("Draft survives thread navigation ✅\nSecond line")

  await page.getByRole("button", { name: "Send message" }).click()
  await expect(page.getByText("Message sent.")).toBeVisible()
  await expect(composer).toHaveValue("")
  const sent = page.locator("article").filter({ hasText: "Draft survives thread navigation" })
  await expect(sent).toContainText("Second line")
  const sentMessageId = await sent.evaluate(article => article.closest("li")?.id)
  if (!sentMessageId) throw new Error("sent message did not have a stable public-id anchor")
  const sentMessage = page.locator(`#${sentMessageId}`)

  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.reload()
  await expect(page.getByRole("region", { name: "Conversation workspace" })).toBeVisible()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-workspace-1440-light.png" })
  }

  await page.setViewportSize({ width: 390, height: 844 })
  await page.locator("html").evaluate(element => element.classList.add("dark"))
  await expect(page.getByRole("button", { name: /Inbox/ })).toBeVisible()
  expect(await list.evaluate(element => element.scrollHeight > element.clientHeight)).toBe(true)
  const narrowComposer = await composer.boundingBox()
  expect(narrowComposer && narrowComposer.y + narrowComposer.height <= 844).toBe(true)
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-workspace-390-dark.png" })
  }

  await sentMessage.getByRole("button", { name: "Edit" }).click()
  await sentMessage.getByLabel("Edit message").fill("Edited in the React workspace ✅")
  await sentMessage.getByRole("button", { name: "Save" }).click()
  await expect(page.getByText("Edited in the React workspace ✅")).toBeVisible()
  await sentMessage.getByRole("button", { name: "Mark read through here" }).click()
  await expect(page.getByText("Read position updated.")).toBeVisible()
})
