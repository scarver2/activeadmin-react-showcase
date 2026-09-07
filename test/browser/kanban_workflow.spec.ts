// test/browser/kanban_workflow.spec.ts

import { expect, test } from "@playwright/test"

test("persists a Rails-authoritative Kanban move after drag and reload", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/kanban_workflow")

  const card = page.locator("li[draggable=true]").filter({ hasText: "Document import edge cases" })
  const reviewColumn = page.getByRole("region", { name: "Review workflow column" })
  await card.dragTo(reviewColumn)
  await expect(reviewColumn).toContainText("Document import edge cases")

  await page.reload()
  await expect(page.getByRole("region", { name: "Review workflow column" })).toContainText("Document import edge cases")
})
