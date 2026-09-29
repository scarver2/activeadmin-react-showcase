// test/browser/conversation_acceptance.spec.ts

import { expect, test } from "@playwright/test"
import type { Page } from "@playwright/test"

async function signIn(page: Page) {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
}

test("keeps an accessible new-message boundary while the reader is away from newest", async ({ browser }) => {
  const readerContext = await browser.newContext()
  const senderContext = await browser.newContext()
  const reader = await readerContext.newPage()
  const sender = await senderContext.newPage()

  try {
    await reader.setViewportSize({ width: 1440, height: 1000 })
    await signIn(reader)
    await signIn(sender)
    await reader.goto("/admin/conversations/release-coordination")
    await sender.goto("/admin/conversations/release-coordination")
    await expect(reader.getByTestId("conversation-cable-status")).toHaveText("Messages live")

    const list = reader.getByRole("list", { name: "Messages" })
    expect(await list.evaluate(element => element.scrollHeight > element.clientHeight)).toBe(true)
    await list.evaluate(element => { element.scrollTop = 0 })

    const body = `Unread boundary ${Date.now()}`
    await sender.getByLabel("Message as You").fill(body)
    await sender.getByRole("button", { name: "Send message" }).click()

    const divider = reader.getByRole("separator", { name: "1 new message" })
    const jump = divider.getByRole("button", { name: "1 new message · Jump to newest" })
    await expect(divider).toBeVisible()
    await expect(reader.locator("article").filter({ hasText: body })).toBeVisible()
    expect(await divider.evaluate((element, expectedBody) => element.nextElementSibling?.textContent?.includes(expectedBody), body)).toBe(true)

    await divider.scrollIntoViewIfNeeded()
    if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
      await reader.screenshot({ fullPage: true, path: "docs/screenshots/conversation-acceptance-1440-light.png" })
      await reader.setViewportSize({ width: 390, height: 844 })
      await reader.locator("html").evaluate(element => element.classList.add("dark"))
      await divider.scrollIntoViewIfNeeded()
      await reader.screenshot({ fullPage: true, path: "docs/screenshots/conversation-acceptance-390-dark.png" })
    }

    await jump.focus()
    await reader.keyboard.press("Enter")
    await expect(divider).toHaveCount(0)

    const question = reader.locator("article").filter({ hasText: body }).getByRole("button", { name: /Question message by You, 0 total/ })
    await question.focus()
    await reader.keyboard.press("Space")
    await expect(reader.locator("article").filter({ hasText: body }).getByRole("button", { name: /Question message by You, 1 total/ })).toHaveAttribute("aria-pressed", "true")

    const composer = reader.getByRole("combobox", { name: "Message as You" })
    await composer.focus()
    await reader.keyboard.type("@Ril")
    await expect(reader.getByRole("option", { name: /Riley Chen/ })).toHaveAttribute("aria-selected", "true")
    await reader.keyboard.press("Enter")
    await expect(composer).toHaveValue("@Riley Chen ")
  } finally {
    await readerContext.close()
    await senderContext.close()
  }
})

test("reconnects the real Cable client and resumes canonical invalidation delivery", async ({ browser }) => {
  test.setTimeout(45_000)
  const readerContext = await browser.newContext()
  const senderContext = await browser.newContext()
  await readerContext.addInitScript(() => {
    const NativeWebSocket = window.WebSocket
    const trackedWindow = window as typeof window & { __conversationAcceptanceSockets: WebSocket[] }
    trackedWindow.__conversationAcceptanceSockets = []
    class TrackedWebSocket extends NativeWebSocket {
      constructor(url: string | URL, protocols?: string | string[]) {
        super(url, protocols || [])
        trackedWindow.__conversationAcceptanceSockets.push(this)
      }
    }
    window.WebSocket = TrackedWebSocket
  })
  const reader = await readerContext.newPage()
  const sender = await senderContext.newPage()

  try {
    await signIn(reader)
    await signIn(sender)
    await reader.goto("/admin/conversations/release-coordination")
    await sender.goto("/admin/conversations/release-coordination")
    const status = reader.getByTestId("conversation-cable-status")
    await expect(status).toHaveText("Messages live")

    const initialSocketCount = await reader.evaluate(() => {
      const trackedWindow = window as typeof window & { __conversationAcceptanceSockets: WebSocket[] }
      return trackedWindow.__conversationAcceptanceSockets.length
    })
    await reader.evaluate(() => {
      const trackedWindow = window as typeof window & { __conversationAcceptanceSockets: WebSocket[] }
      const cables = trackedWindow.__conversationAcceptanceSockets.filter(socket => socket.url.includes("/cable") && socket.readyState === WebSocket.OPEN)
      if (cables.length === 0) throw new Error("A live Action Cable socket was not observed")
      cables.forEach(socket => socket.close(4001, "Deterministic reconnect acceptance probe"))
    })
    await expect.poll(() => reader.evaluate(count => {
      const trackedWindow = window as typeof window & { __conversationAcceptanceSockets: WebSocket[] }
      return trackedWindow.__conversationAcceptanceSockets.length > count &&
        trackedWindow.__conversationAcceptanceSockets.some(socket => socket.readyState === WebSocket.OPEN)
    }, initialSocketCount), { timeout: 20_000 }).toBe(true)
    await expect(status).toHaveText("Messages live", { timeout: 20_000 })

    const body = `Reconnect delivery ${Date.now()}`
    await sender.getByLabel("Message as You").fill(body)
    await sender.getByRole("button", { name: "Send message" }).click()
    await expect(reader.getByText(body)).toBeVisible()
  } finally {
    await readerContext.close()
    await senderContext.close()
  }
})

test("keeps durable Rails messaging available when Cable cannot connect", async ({ browser }) => {
  const degradedContext = await browser.newContext()
  await degradedContext.routeWebSocket(/\/cable(?:\?.*)?$/u, socket => {
    void socket.close({ code: 1013, reason: "Deterministic Cable degradation probe" })
  })
  const page = await degradedContext.newPage()

  try {
    await signIn(page)
    await page.goto("/admin/conversations/release-coordination")
    await expect(page.getByTestId("conversation-cable-status")).toContainText("Rails messaging remains available")

    const body = `Durable without Cable ${Date.now()}`
    await page.getByLabel("Message as You").fill(body)
    await page.getByRole("button", { name: "Send message" }).click()
    await expect(page.getByText("Message sent.")).toBeVisible()
    await expect(page.locator("article").filter({ hasText: body })).toBeVisible()
  } finally {
    await degradedContext.close()
  }
})
