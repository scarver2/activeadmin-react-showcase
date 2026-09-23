import { expect, test } from "@playwright/test"

const signIn = async (page: import("@playwright/test").Page) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin$/)
}

for (const width of [1440, 390]) {
  test(`Video Toaster 4000 preserves AA4 behavior at ${width}px`, async ({ browser }) => {
    const context = await browser.newContext({ viewport: { width, height: 1000 } })
    const page = await context.newPage()
    await signIn(page)
    await page.goto("/admin/video_toaster_4000_laboratory")

    await expect(page).toHaveTitle(/Video Toaster 4000 \/ LightWave — Heritage Laboratory/)
    await expect(page.locator("body")).toHaveAttribute("data-activeadmin-theme", "video_toaster_4000")
    await expect(page.locator('[data-activeadmin-theme="haiku_beta6"]')).toHaveCount(0)
    const study = page.getByRole("region", { name: "Video Toaster 4000 design study", exact: true })
    await expect(study).toBeVisible()
    await expect(study).toHaveCSS("color", "rgb(240, 240, 240)")
    await expect(study).toHaveCSS("--video-toaster-4000-field", "#514b56")
    await expect(study).toHaveCSS("--video-toaster-4000-amber", "#ffef75")
    await expect(study).toHaveCSS("font-family", /ui-monospace/)

    const dataRegion = study.getByRole("region", { name: "Account records", exact: true })
    await expect(dataRegion).toHaveAttribute("tabindex", "0")
    await expect(dataRegion).toHaveCSS("overflow-x", "auto")
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)

    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await expect(study).toHaveCSS("color", "rgb(240, 240, 240)")
    await expect(study).toHaveCSS("--video-toaster-4000-field", "#514b56")
    await page.locator("html").evaluate(element => element.classList.remove("dark"))

    if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
      await page.screenshot({ fullPage: true, path: `docs/screenshots/video-toaster-4000-${width}.png` })
    }

    const allRecords = await study.locator("tbody tr").count()
    await study.getByLabel("Account status").selectOption("trial")
    await study.getByRole("button", { name: "Route View", exact: true }).focus()
    await page.keyboard.press("Enter")
    await expect(page).toHaveURL(/status=trial/)
    const statusTags = study.locator("tbody td:last-child span")
    await expect(statusTags).not.toHaveCount(0)
    expect((await statusTags.allTextContents()).every(status => status === "trial")).toBe(true)
    await study.getByRole("link", { name: "Reset", exact: true }).click()
    await expect(study.locator("tbody tr")).toHaveCount(allRecords)

    await study.getByText("Reference, provenance & modern adaptations", { exact: true }).click()
    await expect(study.getByText(/all 24 semantic roles/)).toBeVisible()
    await page.emulateMedia({ reducedMotion: "reduce", forcedColors: "active" })
    await study.getByLabel("Account status").focus()
    expect(await study.getByLabel("Account status").evaluate(node => getComputedStyle(node).outlineStyle)).not.toBe("none")
    await page.emulateMedia({ reducedMotion: "no-preference", forcedColors: "none" })
    await study.getByRole("link", { name: "Open Accounts application" }).click()
    await expect(page).toHaveURL(/\/admin\/accounts$/)
    await expect(page.locator('[data-activeadmin-theme="video_toaster_4000"]')).toHaveCount(0)
    await context.close()
  })
}

test("Video Toaster 4000 form and record links remain useful without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 844 } })
  const page = await context.newPage()
  await signIn(page)
  await page.goto("/admin/video_toaster_4000_laboratory")
  await page.getByLabel("Account status").selectOption("trial")
  await page.getByRole("button", { name: "Route View", exact: true }).click()
  await expect(page).toHaveURL(/status=trial/)
  const study = page.getByRole("region", { name: "Video Toaster 4000 design study", exact: true })
  const statusTags = study.locator("tbody td:last-child span")
  await expect(statusTags).not.toHaveCount(0)
  expect((await statusTags.allTextContents()).every(status => status === "trial")).toBe(true)
  await study.locator("tbody a").first().click()
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+$/)
  await context.close()
})
