// app/frontend/navigation/nativeNavigation.test.ts

import { initDrawers, initDropdowns } from "flowbite"
import instances from "flowbite/lib/esm/dom/instances"

import { startNativeNavigation } from "./nativeNavigation"

vi.mock("flowbite", () => ({
  initDrawers: vi.fn(),
  initDropdowns: vi.fn()
}))
vi.mock("flowbite/lib/esm/dom/instances", () => ({ default: { getInstance: vi.fn(), instanceExists: vi.fn() } }))

it("reuses native navigation on Turbo visits and closes the drawer before caching", () => {
  const hide = vi.fn()
  vi.mocked(instances.getInstance).mockReturnValue({ hide })
  vi.mocked(instances.instanceExists).mockReturnValue(false)
  const stop = startNativeNavigation()
  document.dispatchEvent(new Event("turbo:load"))
  expect(initDrawers).toHaveBeenCalledOnce()
  expect(initDropdowns).toHaveBeenCalledOnce()
  document.dispatchEvent(new Event("turbo:before-cache"))
  expect(hide).not.toHaveBeenCalled()
  vi.mocked(instances.instanceExists).mockReturnValue(true)
  document.dispatchEvent(new Event("turbo:before-cache"))
  expect(instances.getInstance).toHaveBeenCalledWith("Drawer", "main-menu")
  expect(hide).toHaveBeenCalledOnce()
  stop()
  document.dispatchEvent(new Event("turbo:load"))
  document.dispatchEvent(new Event("turbo:before-cache"))
  expect(initDrawers).toHaveBeenCalledOnce()
  expect(hide).toHaveBeenCalledOnce()
})
