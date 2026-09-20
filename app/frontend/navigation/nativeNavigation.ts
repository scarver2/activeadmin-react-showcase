// app/frontend/navigation/nativeNavigation.ts

import { type DrawerInterface, initDrawers, initDropdowns } from "flowbite"
import instances from "flowbite/lib/esm/dom/instances"

// ActiveAdmin loads Flowbite for window.load; Turbo visits need the same native wiring.
export function startNativeNavigation() {
  function initialize() {
    initDrawers()
    initDropdowns()
  }

  function closeDrawer() {
    if (instances.instanceExists("Drawer", "main-menu")) {
      const drawer = instances.getInstance("Drawer", "main-menu") as DrawerInterface
      drawer.hide()
    }
  }

  document.addEventListener("turbo:load", initialize)
  document.addEventListener("turbo:before-cache", closeDrawer)
  return () => {
    document.removeEventListener("turbo:load", initialize)
    document.removeEventListener("turbo:before-cache", closeDrawer)
  }
}
