// test/browser/social_graph.spec.ts

import { expect, test } from "@playwright/test"

test("explores the cross-generation graph and highlights Luke and Vader", async ({ page }) => {
  await page.setViewportSize({ height: 1100, width: 1440 })
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/social_network")
  await expect(page.getByTestId("social-graph").locator("canvas").first()).toBeVisible()
  await expect(page.getByRole("region", { name: "Relationship path" })).toContainText("Luke Skywalker — father and son → Darth Vader")
  await page.getByRole("button", { name: "3 degrees" }).click()
  await expect(page.getByRole("region", { name: "People" })).toContainText("Ben Solo / Kylo Ren")
  await expect(page.getByRole("region", { name: "People" })).toContainText("Rey")
  await page.getByRole("button", { name: "Darth Vader" }).click()
  await expect(page.getByRole("region", { name: "Selected person" })).toContainText("Former Jedi and Luke's father")
  await page.getByRole("button", { name: "Fit graph" }).click()
  if (process.env.CAPTURE_SHOWCASE_SCREENSHOTS) {
    await page.screenshot({ path: "docs/screenshots/social-graph.png" })
  }
})
