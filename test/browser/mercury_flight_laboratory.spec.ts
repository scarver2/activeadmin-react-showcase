// test/browser/mercury_flight_laboratory.spec.ts
import { expect, test } from "@playwright/test"

const signIn = async (page: import("@playwright/test").Page) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin$/)
}

for (const width of [1440, 390]) {
  test(`Mercury Flight preserves AA4 behavior at ${width}px`, async ({ browser }) => {
    const context = await browser.newContext({ viewport: { width, height: 1000 } })
    const page = await context.newPage()
    await signIn(page)
    await page.goto("/admin/mercury_flight_laboratory")

    await expect(page).toHaveTitle(/Mercury Flight — Heritage Laboratory/)
    await expect(page.locator("body")).toHaveAttribute("data-activeadmin-theme", "mercury_flight")
    await expect(page.locator('[data-activeadmin-theme="video_toaster_4000"]')).toHaveCount(0)
    const study = page.getByRole("region", { name: "Mercury Flight design study", exact: true })
    await expect(study).toBeVisible()
    await expect(study).toHaveCSS("color", "rgb(47, 48, 51)")
    await expect(study).toHaveCSS("--mercury-flight-backdrop", "#3c110b")
    await expect(study).toHaveCSS("--mercury-flight-coral", "#e44d34")
    await expect(study).toHaveCSS("font-family", /system-ui/)

    const dataRegion = study.getByRole("region", { name: "Account records", exact: true })
    await expect(dataRegion).toHaveAttribute("tabindex", "0")
    await expect(dataRegion).toHaveCSS("overflow-x", "auto")
    await expect(dataRegion.locator("tbody th a").first()).toHaveCSS("color", "rgb(167, 56, 41)")
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)

    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await expect(study).toHaveCSS("color", "rgb(47, 48, 51)")
    await expect(study).toHaveCSS("--mercury-flight-backdrop", "#3c110b")
    await page.locator("html").evaluate(element => element.classList.remove("dark"))

    if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
      await page.screenshot({ fullPage: true, path: `docs/screenshots/mercury-flight-${width}.png` })
    }

    const allRecords = await study.locator("tbody tr").count()
    await study.getByLabel("Account status").selectOption("trial")
    await study.getByRole("button", { name: "Update Flight Plan", exact: true }).focus()
    await page.keyboard.press("Enter")
    await expect(page).toHaveURL(/status=trial/)
    const statusTags = study.locator("tbody td:last-child span")
    await expect(statusTags).not.toHaveCount(0)
    expect((await statusTags.allTextContents()).every(status => status === "trial")).toBe(true)
    await study.getByRole("link", { name: "Reset", exact: true }).click()
    await expect(study.locator("tbody tr")).toHaveCount(allRecords)

    const disclosure = study.locator("details")
    await disclosure.locator("summary").focus()
    await page.keyboard.press("Enter")
    await expect(disclosure).toHaveAttribute("open", "")
    await expect(study.getByText(/all 24 semantic roles/)).toBeVisible()
    await page.emulateMedia({ reducedMotion: "reduce", forcedColors: "active" })
    await study.getByLabel("Account status").focus()
    expect(await study.getByLabel("Account status").evaluate(node => getComputedStyle(node).outlineStyle)).not.toBe("none")
    await page.emulateMedia({ reducedMotion: "no-preference", forcedColors: "none" })
    await study.getByRole("link", { name: "Open Accounts application" }).click()
    await expect(page).toHaveURL(/\/admin\/accounts$/)
    await expect(page.locator('[data-activeadmin-theme="mercury_flight"]')).toHaveCount(0)
    await context.close()
  })
}

test("Mercury Flight form and record links remain useful without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 844 } })
  const page = await context.newPage()
  await signIn(page)
  await page.goto("/admin/mercury_flight_laboratory")
  await page.getByLabel("Account status").selectOption("trial")
  await page.getByRole("button", { name: "Update Flight Plan", exact: true }).click()
  await expect(page).toHaveURL(/status=trial/)
  const study = page.getByRole("region", { name: "Mercury Flight design study", exact: true })
  const statusTags = study.locator("tbody td:last-child span")
  await expect(statusTags).not.toHaveCount(0)
  expect((await statusTags.allTextContents()).every(status => status === "trial")).toBe(true)
  await study.locator("tbody a").first().click()
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+$/)
  await context.close()
})
