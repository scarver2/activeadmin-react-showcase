// test/browser/hierarchy_explorer.spec.ts

import { expect, test } from "@playwright/test"

test("lazily explores and keyboard-reparents the Rails-owned hierarchy", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/hierarchy_explorer")

  await page.getByRole("button", { name: "Expand Showcase Company" }).click()
  await expect(page.getByRole("button", { exact: true, name: "Engineering" })).toBeVisible()
  await page.getByRole("button", { exact: true, name: "Studio" }).click()
  await page.getByRole("button", { name: "Move Studio here" }).first().click()
  await expect(page.getByRole("navigation", { name: "Selected node breadcrumbs" })).toContainText("Studio")

  await page.reload()
  await page.getByRole("button", { name: "Expand Showcase Company" }).click()
  await expect(page.getByRole("treeitem", { name: /Showcase Company/ })).toContainText("Studio")
})

test("drags a node and rejects a cycle without losing the tree", async ({ page }) => {
  await page.goto("/admin/login")
  await page.getByLabel("Email").fill("admin@example.test")
  await page.getByLabel("Password").fill("showcase-password")
  await page.getByRole("button", { name: "Sign In" }).click()
  await expect(page).toHaveURL(/\/admin(?:\/)?$/)
  await page.goto("/admin/hierarchy_explorer")

  await page.getByRole("button", { name: "Expand Showcase Company" }).click()
  const root = page.getByRole("treeitem", { name: /Showcase Company/ })
  const engineering = page.getByRole("treeitem", { name: /Engineering/ })
  await root.dragTo(engineering)

  await expect(page.getByRole("alert")).toContainText("cycle")
  await expect(root).toBeVisible()
})
