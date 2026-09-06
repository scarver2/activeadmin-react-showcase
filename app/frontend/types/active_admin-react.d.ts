// app/frontend/types/active_admin-react.d.ts

declare module "active_admin/react" {
  import type { ComponentType } from "react"

  export function registerComponent<Props extends object>(
    name: string,
    component: ComponentType<Props>
  ): void
  export function start(): void
}
