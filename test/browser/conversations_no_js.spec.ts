// test/browser/conversations_no_js.spec.ts

import { expect, test } from "@playwright/test"

test.use({ javaScriptEnabled: false })

test("uses the authenticated conversation inbox and mutations without JavaScript", async ({ page }) => {
  const messageBody = `No-JavaScript handoff ${Date.now()} ✅`
  const editedBody = `Edited without JavaScript ${Date.now()} ✅`
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)

  await page.goto("/admin/conversations")
  await expect(page.getByRole("heading", { name: "Inbox" })).toBeVisible()
  await page.getByRole("link", { name: "Release coordination" }).click()
  for (let pageNumber = 0; pageNumber < 10 && await page.getByText("The release candidate is ready for the final accessibility pass.").count() === 0; pageNumber += 1) {
    const older = page.getByRole("link", { name: "Load 50 older messages" })
    if (await older.count() === 0) break
    await older.click()
  }
  const releaseSource = page.locator("#message-release-coordination-message-1")
  await expect(releaseSource.locator("article > p").filter({ hasText: "The release candidate is ready for the final accessibility pass." })).toBeVisible()
  await expect(page.getByRole("link", { name: "release-checklist.txt" })).toBeVisible()
  await page.locator("details").getByText("4 participants", { exact: true }).click()
  await expect(page.getByRole("list", { name: "Conversation participants" }).getByText("Riley Chen")).toBeVisible()
  const seededMessage = releaseSource.locator("article")
  await expect(seededMessage.getByRole("button", { name: "Like message by Release Lead, 1 total" }))
    .toHaveAttribute("aria-pressed", "false")
  await expect(seededMessage.getByRole("button", { name: "Question message by Release Lead, 1 total" }))
    .toHaveAttribute("aria-pressed", "true")

  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversations-no-js-1440-light.png" })
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-dispositions-no-js-1440-light.png" })
    await page.setViewportSize({ width: 390, height: 844 })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await expect(page.locator("#main-menu")).not.toBeInViewport()
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversations-no-js-390-dark.png" })
    await page.screenshot({ fullPage: true, path: "docs/screenshots/conversation-dispositions-no-js-390-dark.png" })
  }

  await seededMessage.getByRole("button", { name: "Dislike message by Release Lead, 0 total" }).click()
  const changedSeededMessage = page.locator("article")
    .filter({ hasText: "The release candidate is ready for the final accessibility pass." })
  await expect(changedSeededMessage.getByRole("button", { name: "Dislike message by Release Lead, 1 total" }))
    .toHaveAttribute("aria-pressed", "true")
  await changedSeededMessage.getByRole("button", { name: "Dislike message by Release Lead, 1 total" }).click()
  await expect(page.locator("article")
    .filter({ hasText: "The release candidate is ready for the final accessibility pass." })
    .getByRole("button", { name: "Dislike message by Release Lead, 0 total" }))
    .toHaveAttribute("aria-pressed", "false")

  await page.locator("#message-release-coordination-message-1 article")
    .getByRole("link", { name: "Reply" }).click()
  await expect(page.locator("#composer").getByText("Replying to Release Lead", { exact: true })).toBeVisible()

  await page.getByLabel("Message", { exact: true }).fill(`${messageBody}\nSecond line @Riley Chen`)
  await page.getByLabel("Mention participants (optional)").selectOption("riley-chen")
  await page.getByLabel("Attachment (optional)").setInputFiles({
    buffer: Buffer.from("No-JavaScript attachment proof\n"),
    mimeType: "text/plain",
    name: "no-js-proof.txt"
  })
  await page.getByRole("button", { name: "Send message" }).click()
  const sent = page.locator("article").filter({ hasText: messageBody })
  await expect(sent).toContainText("Second line")
  await expect(sent.getByRole("link", { name: "Replying to Release Lead" })).toBeVisible()
  await expect(sent.locator("mark[data-member-key='riley-chen']")).toHaveText("@Riley Chen")
  await expect(sent.getByRole("link", { name: "Message link" })).toHaveAttribute("href", /^#message-/)
  await expect(sent.getByRole("link", { name: "no-js-proof.txt" })).toBeVisible()
  const messageId = await sent.evaluate(article => article.closest("li")?.id)
  if (!messageId) throw new Error("no-JavaScript message did not have a stable public-id anchor")

  await sent.getByRole("link", { name: "Edit message" }).click()
  await page.getByLabel("Message text").fill(editedBody)
  await page.getByRole("button", { name: "Save message" }).click()
  const edited = page.locator(`#${messageId}`).locator("article")
  await expect(edited).toContainText(editedBody)
  await expect(edited).toContainText("edited")

  await edited.getByRole("button", { name: "Mark read through here" }).click()
  await expect(page.getByText("Read position updated.")).toBeVisible()
  await edited.getByRole("button", { name: "Mark unread from here" }).click()
  await expect(page.getByText("Unread position updated.")).toBeVisible()

  await edited.getByRole("button", { name: "Withdraw message" }).click()
  await expect(page.locator(`#${messageId}`).getByText(MessageTombstone, { exact: true })).toBeVisible()
})

test("keeps saved messages private, contextual, and useful without JavaScript", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()

  await page.goto("/admin/conversations/release-coordination")
  const ownMessage = page.locator("article")
    .filter({ has: page.getByRole("button", { name: "Withdraw message" }) })
    .filter({ has: page.getByRole("button", { name: "Save message" }) })
    .last()
  const ownMessageBody = (await ownMessage.locator("p").first().textContent()) || ""
  const ownMessageId = await ownMessage.evaluate(article => article.closest("li")?.id)
  if (!ownMessageId) throw new Error("saved message did not have a stable public-id anchor")
  await ownMessage.getByRole("button", { name: "Save message" }).click()
  await expect(page.getByText("Message saved.")).toBeVisible()
  await page.locator(`#${ownMessageId}`).getByRole("button", { name: "Withdraw message" }).click()

  await page.getByRole("link", { name: "Saved messages" }).click()
  await expect(page.getByRole("heading", { level: 2, name: "Saved messages" })).toBeVisible()
  await expect(page.getByText("Release Lead")).toBeVisible()
  await expect(page.getByText(MessageTombstone)).toBeVisible()
  await expect(page.getByText(ownMessageBody, { exact: true })).toHaveCount(0)
  await expect(page.getByRole("link", { name: "Open in conversation" }).first()).toHaveAttribute(
    "href",
    /\/admin\/conversations\/release-coordination#message-/
  )

  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS === "1") {
    await page.screenshot({ fullPage: true, path: "docs/screenshots/saved-messages-1440-light.png" })
    await page.setViewportSize({ width: 390, height: 844 })
    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await expect(page.locator("#main-menu")).not.toBeInViewport()
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
    await page.screenshot({ fullPage: true, path: "docs/screenshots/saved-messages-390-dark.png" })
  }
})

const MessageTombstone = "[withdrawn]"
