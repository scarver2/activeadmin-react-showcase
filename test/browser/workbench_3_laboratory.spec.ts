// test/browser/workbench_3_laboratory.spec.ts
import { expect, test } from "@playwright/test"

const signIn = async (page: import("@playwright/test").Page) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin$/)
}

for (const width of [1440, 390]) {
  test(`Workbench 3.x preserves AA4 behavior at ${width}px`, async ({ browser }) => {
    const context = await browser.newContext({ viewport: { width, height: 1000 } })
    const page = await context.newPage()
    await signIn(page)
    await page.goto("/admin/workbench_3_laboratory")

    await expect(page).toHaveTitle(/Workbench 3.x — Heritage Laboratory/)
    await expect(page.locator("body")).toHaveAttribute("data-activeadmin-theme", "workbench-3")
    await expect(page.locator('[data-activeadmin-theme="workbench-2"], [data-activeadmin-theme="workbench-13"]')).toHaveCount(0)
    const study = page.getByRole("region", { name: "Workbench 3.x design study", exact: true })
    await expect(study).toBeVisible()
    await expect(study).toHaveCSS("background-color", "rgb(143, 143, 143)")
    await expect(study).toHaveCSS("background-image", /repeating-conic-gradient/)
    await expect(study.getByRole("button", { name: "Use", exact: true })).toHaveCSS("background-color", "rgb(99, 130, 181)")
    await expect(study.getByRole("button", { name: "Use", exact: true })).toHaveCSS("color", "rgb(8, 8, 8)")
    await expect(study.getByRole("link", { name: "Reset", exact: true })).toHaveCSS("color", "rgb(8, 8, 8)")

    const dataRegion = study.getByRole("region", { name: "Account records", exact: true })
    await expect(dataRegion).toHaveAttribute("tabindex", "0")
    await expect(dataRegion).toHaveCSS("overflow-x", "auto")
    if (width === 390) {
      expect(await dataRegion.evaluate(element => element.scrollWidth > element.clientWidth)).toBe(true)
    }
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)

    await page.locator("html").evaluate(element => element.classList.add("dark"))
    await expect(study).toHaveCSS("background-color", "rgb(143, 143, 143)")
    await page.locator("html").evaluate(element => element.classList.remove("dark"))

    if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
      await page.screenshot({ fullPage: true, path: `docs/screenshots/workbench-3-${width}.png` })
    }

    const allRecords = await study.locator("tbody tr").count()
    await study.getByLabel("Account status").selectOption("trial")
    await study.getByRole("button", { name: "Use", exact: true }).focus()
    await page.keyboard.press("Enter")
    await expect(page).toHaveURL(/status=trial/)
    const statusTags = study.locator("tbody td:last-child span")
    await expect(statusTags).not.toHaveCount(0)
    expect((await statusTags.allTextContents()).every(status => status === "trial")).toBe(true)
    await expect(study.getByRole("status")).toContainText("trial")
    await study.getByRole("link", { name: "Reset", exact: true }).click()
    await expect(study.locator("tbody tr")).toHaveCount(allRecords)

    await study.getByText("Reference & modern adaptations", { exact: true }).click()
    await expect(study.getByText(/documented Workbench 3.x capture sets/)).toBeVisible()
    await page.emulateMedia({ reducedMotion: "reduce", forcedColors: "active" })
    await study.getByLabel("Account status").focus()
    expect(await study.getByLabel("Account status").evaluate(node => getComputedStyle(node).outlineStyle)).not.toBe("none")
    await page.emulateMedia({ reducedMotion: "no-preference", forcedColors: "none" })
    await study.getByRole("link", { name: "Open full Accounts directory" }).click()
    await expect(page).toHaveURL(/\/admin\/accounts$/)
    await expect(page.locator('[data-activeadmin-theme="workbench-3"]')).toHaveCount(0)
    await context.close()
  })
}

test("Workbench 3.x form and links remain useful without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 844 } })
  const page = await context.newPage()
  await signIn(page)
  await page.goto("/admin/workbench_3_laboratory")
  await page.getByLabel("Account status").selectOption("trial")
  await page.getByRole("button", { name: "Use", exact: true }).click()
  await expect(page).toHaveURL(/status=trial/)
  const statusTags = page.getByRole("region", { name: "Workbench 3.x design study", exact: true })
    .locator("tbody td:last-child span")
  await expect(statusTags).not.toHaveCount(0)
  expect((await statusTags.allTextContents()).every(status => status === "trial")).toBe(true)
  await page.getByRole("region", { name: "Workbench 3.x design study", exact: true })
    .locator("tbody a").first().click()
  await expect(page).toHaveURL(/\/admin\/accounts\/\d+$/)
  await context.close()
})
