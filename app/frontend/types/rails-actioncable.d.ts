// app/frontend/types/rails-actioncable.d.ts

declare module "@rails/actioncable" {
  type Consumer = {
    connect(): void
    disconnect(): void
    subscriptions: {
      create(identifier: Record<string, unknown>, callbacks: Record<string, unknown>): { perform(action: string, data?: object): boolean, unsubscribe(): void }
    }
  }

  export function createConsumer(url?: string): Consumer
}
