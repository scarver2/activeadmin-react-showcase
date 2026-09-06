// app/frontend/types/active_admin-react.d.ts

declare module "active_admin/react" {
  import type { ComponentType } from "react"

  export function registerComponent<Props extends object>(
    name: string,
    component: ComponentType<Props>
  ): void
  export function start(): void

  export type OperationValue = {
    operationId: string | null
    idempotencyKey: string | null
    sequence: number | null
    state: string
    progress: number | null
    message: string | null
    result: string | null
    error: { code: string | null; message: string | null; retryable: boolean; details: unknown } | null
    occurredAt: string | null
  }

  export class OperationState {
    constructor(initial?: Record<string, unknown>)
    value: OperationValue
    lastSequence: number | null
  }

  export function operationAccessibility(operation: OperationState | OperationValue): {
    role: "status" | "alert"
    "aria-live": "polite" | "assertive"
    "aria-busy": boolean
  }

  export function subscribeToOperation(options: Record<string, unknown>): { unsubscribe(): void }
  export function requestOperationCancellation(options: Record<string, unknown>): Promise<Record<string, unknown>>
}
