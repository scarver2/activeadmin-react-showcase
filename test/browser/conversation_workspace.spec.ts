// test/browser/conversation_workspace.spec.ts

import { expect, test } from "@playwright/test"
import type { Page } from "@playwright/test"

async function signIn(page: Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

test("enhances the durable conversation workflow at desktop and narrow widths", async ({ page }) => {
  const draftBody = `Draft survives thread navigation ${Date.now()} ✅`
  const editedBody = `Edited in the React workspace ${Date.now()} ✅`
  await page.context().grantPermissions([ "clipboard-read", "clipboard-write" ])
  await page.setViewportSize({ width: 1440, height: 1000 })
  await signIn(page)

  await page.goto("/admin/conversations/release-coordination")
  await expect(page.getByRole("region", { name: "Conversation workspace" })).toBeVisible()
  await expect(page.locator("[data-conversation-fallback='thread']")).toHaveCount(0)
  const participantSummary = page.locator(".conversation-participants").getByText("4 participants", { exact: true })
  await participantSummary.click()
  await expect(page.getByRole("list", { name: "Conversation participants" }).getByText("Riley Chen")).toBeVisible()
  await participantSummary.click()

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

  await composer.fill(`${draftBody}\nSecond line`)
  await page.setViewportSize({ width: 390, height: 844 })
  await page.getByRole("button", { name: /Inbox/ }).click()
  await expect(page.getByRole("heading", { name: "Conversations" })).toBeFocused()
  await page.getByRole("link", { name: /Release coordination/ }).click()
  await expect(page.getByRole("region", { name: "Conversation workspace" }).getByRole("heading", { name: "Release coordination" })).toBeFocused()
  await expect(composer).toHaveValue(`${draftBody}\nSecond line`)

  await page.locator("article").last().getByRole("button", { name: "Reply" }).click()
  await expect(page.getByText(/Replying to/).last()).toBeVisible()
  await composer.fill(`${draftBody}\nSecond line @Ril`)
  await expect(page.getByRole("listbox", { name: "Mention suggestions" })).toBeVisible()
  await composer.press("Enter")
  await expect(composer).toHaveValue(`${draftBody}\nSecond line @Riley Chen `)

  await page.getByLabel("Attachment (optional)").setInputFiles({
    buffer: Buffer.from("Synthetic browser attachment\n"),
    mimeType: "text/plain",
    name: "browser-proof.txt"
  })
  await page.getByRole("button", { name: "Send message" }).click()
  await expect(page.getByText("Message sent.")).toBeVisible()
  await expect(composer).toHaveValue("")
  const sent = page.locator("article").filter({ hasText: draftBody })
  await expect(sent).toContainText("Second line")
  const sentMessageId = await sent.evaluate(article => article.closest("li")?.id)
  if (!sentMessageId) throw new Error("sent message did not have a stable public-id anchor")
  const sentMessage = page.locator(`#${sentMessageId}`)
  await expect(sentMessage.locator(".conversation-reply-quote")).toBeVisible()
  await expect(sentMessage.locator("mark[data-member-key='riley-chen']")).toHaveText("@Riley Chen")
  await sentMessage.getByRole("button", { name: "Copy link" }).click()
  await expect(page.getByText("Message link copied.")).toBeVisible()
  await expect(sentMessage.getByRole("time")).toHaveAttribute("aria-label", /^Sent .+/)
  const attachmentLink = sentMessage.getByRole("link", { name: "browser-proof.txt" })
  await expect(attachmentLink).toBeVisible()
  await expect(attachmentLink).not.toHaveAttribute("href", /active_storage/)

  await sentMessage.getByRole("button", { name: "Save message" }).click()
  await expect(page.getByText("Message saved.")).toBeVisible()
  await expect(sentMessage.getByRole("button", { name: "Remove from saved" })).toHaveAttribute("aria-pressed", "true")
  await sentMessage.getByRole("button", { name: "Remove from saved" }).click()
  await expect(page.getByText("Message removed from saved messages.")).toBeVisible()
  await expect(sentMessage.getByRole("button", { name: "Save message" })).toHaveAttribute("aria-pressed", "false")
  await sentMessage.getByRole("button", { name: /Like message by You, 0 total/ }).click()
  await expect(sentMessage.getByRole("button", { name: /Like message by You, 1 total/ })).toHaveAttribute("aria-pressed", "true")

  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.reload()
  await expect(page.getByRole("region", { name: "Conversation workspace" })).toBeVisible()
  await expect(sentMessage.getByRole("link", { name: "browser-proof.txt" })).toBeVisible()
  await sentMessage.getByRole("button", { name: /Like message by You, 1 total/ }).scrollIntoViewIfNeeded()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-workspace-1440-light.png" })
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-attachments-1440-light.png" })
    await sentMessage.screenshot({ path: "docs/screenshots/conversation-reply-mention-1440-light.png" })
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-dispositions-1440-light.png" })
  }

  await page.setViewportSize({ width: 390, height: 844 })
  await page.locator("html").evaluate(element => element.classList.add("dark"))
  await expect(page.getByRole("button", { name: /Inbox/ })).toBeVisible()
  expect(await list.evaluate(element => element.scrollHeight > element.clientHeight)).toBe(true)
  const narrowComposer = await composer.boundingBox()
  expect(narrowComposer && narrowComposer.y + narrowComposer.height <= 844).toBe(true)
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
  await sentMessage.getByRole("button", { name: /Like message by You, 1 total/ }).scrollIntoViewIfNeeded()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-workspace-390-dark.png" })
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-attachments-390-dark.png" })
    const composerPanel = page.locator(".conversation-composer")
    await composerPanel.evaluate(element => { element.setAttribute("hidden", "") })
    await sentMessage.screenshot({ path: "docs/screenshots/conversation-reply-mention-390-dark.png" })
    await sentMessage.screenshot({ path: "docs/screenshots/conversation-dispositions-390-dark.png" })
    await composerPanel.evaluate(element => { element.removeAttribute("hidden") })
  }

  await sentMessage.getByRole("button", { name: "Edit" }).click()
  await sentMessage.getByLabel("Edit message").fill(editedBody)
  await sentMessage.getByRole("button", { name: "Save", exact: true }).click()
  await expect(sentMessage.getByLabel("Edit message")).toHaveCount(0)
  await expect(sentMessage.locator("p").filter({ hasText: editedBody })).toBeVisible()
  await sentMessage.getByRole("button", { name: "Mark read through here" }).click()
  await expect(page.getByText("Read position updated.")).toBeVisible()
})

test("reconciles canonical Rails truth across two independent browser clients", async ({ browser }) => {
  const firstContext = await browser.newContext()
  const secondContext = await browser.newContext()
  const first = await firstContext.newPage()
  const second = await secondContext.newPage()

  try {
    await signIn(first)
    await signIn(second)
    await first.goto("/admin/conversations/release-coordination")
    await second.goto("/admin/conversations/release-coordination")
    await expect(first.getByRole("region", { name: "Conversation workspace" })).toBeVisible()
    await expect(second.getByRole("region", { name: "Conversation workspace" })).toBeVisible()

    const body = `Independent clients ${Date.now()}`
    await first.getByLabel("Message as You").fill(body)
    await first.getByRole("button", { name: "Send message" }).click()
    await expect(second.getByText(body)).toBeVisible()

    const firstArticle = first.locator("article").filter({ hasText: body })
    const messageId = await firstArticle.evaluate(article => article.closest("li")?.id)
    if (!messageId) throw new Error("realtime message did not have a stable public-id anchor")
    const firstMessage = first.locator(`#${messageId}`)
    const secondMessage = second.locator(`#${messageId}`)

    await firstMessage.getByRole("button", { name: /Like message by You, 0 total/ }).click()
    await expect(secondMessage.getByRole("button", { name: /Like message by You, 1 total/ })).toHaveAttribute("aria-pressed", "true")

    await secondMessage.getByRole("button", { name: /Question message by You, 0 total/ }).click()
    await expect(firstMessage.getByRole("button", { name: /Question message by You, 1 total/ })).toHaveAttribute("aria-pressed", "true")
    await expect(firstMessage.getByRole("button", { name: /Like message by You, 0 total/ })).toHaveAttribute("aria-pressed", "false")

    await secondMessage.getByRole("button", { name: /Question message by You, 1 total/ }).click()
    await expect(firstMessage.getByRole("button", { name: /Question message by You, 0 total/ })).toHaveAttribute("aria-pressed", "false")

    await firstArticle.getByRole("button", { name: "Edit" }).click()
    await firstArticle.getByLabel("Edit message").fill(`${body} edited`)
    await firstArticle.getByRole("button", { name: "Save", exact: true }).click()
    await expect(second.getByText(`${body} edited`)).toBeVisible()

    first.on("dialog", dialog => dialog.accept())
    await first.locator("article").filter({ hasText: `${body} edited` }).getByRole("button", { name: "Withdraw" }).click()
    await expect(second.locator(`#${messageId}`).getByText("[withdrawn]", { exact: true })).toBeVisible()
  } finally {
    await firstContext.close()
    await secondContext.close()
  }
})
