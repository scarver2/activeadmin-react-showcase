// app/frontend/types/rails-actioncable.d.ts

declare module "@rails/actioncable" {
  type Consumer = {
    connect(): void
    disconnect(): void
    subscriptions: { create(identifier: Record<string, unknown>, callbacks: Record<string, unknown>): unknown }
  }

  export function createConsumer(url?: string): Consumer
}
