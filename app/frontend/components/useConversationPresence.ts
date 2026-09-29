// app/frontend/components/useConversationPresence.ts

import { useCallback, useEffect, useRef, useState, type MutableRefObject } from "react"

export type ConversationPresenceConfig = {
  channel: string
  heartbeatIntervalMs: number
  typingIdleMs: number
}

type CableConsumer = {
  subscriptions: {
    create(identifier: Record<string, unknown>, callbacks: Record<string, unknown>): CableSubscription
  }
}

type CableSubscription = {
  perform(action: string, data?: object): boolean
  unsubscribe(): void
}

type PresenceEnvelope = {
  conversationPublicId: string
  kind: string
  online: string[]
  serverAt: string
  typing: string[]
}

type PresenceState = {
  available: boolean
  online: string[]
  typing: string[]
}

const EMPTY_STATE: PresenceState = { available: false, online: [], typing: [] }

function sessionId() {
  const random = globalThis.crypto?.randomUUID?.().replaceAll("-", "")
  return random || `presence_${Date.now().toString(36)}_${Math.random().toString(36).slice(2)}`
}

function validNames(value: unknown): value is string[] {
  return Array.isArray(value) && value.length <= 100 && value.every(name => typeof name === "string" && name.length <= 100)
}

function validEnvelope(envelope: PresenceEnvelope, conversationPublicId: string) {
  return envelope?.conversationPublicId === conversationPublicId &&
    envelope.kind === "presence" &&
    validNames(envelope.online) &&
    validNames(envelope.typing) &&
    typeof envelope.serverAt === "string" && !Number.isNaN(Date.parse(envelope.serverAt))
}

export default function useConversationPresence(
  consumer: CableConsumer,
  conversationPublicId: string | undefined,
  config: ConversationPresenceConfig | undefined
) {
  const [state, setState] = useState<PresenceState>(EMPTY_STATE)
  const subscription = useRef<CableSubscription | null>(null)
  const heartbeatTimer = useRef<number | null>(null)
  const typingTimer = useRef<number | null>(null)
  const typingActive = useRef(false)
  const typingSentAt = useRef(0)
  const session = useRef(sessionId())

  const clearTimer = (timer: MutableRefObject<number | null>) => {
    if (timer.current !== null) window.clearTimeout(timer.current)
    timer.current = null
  }

  const clearHeartbeat = () => {
    if (heartbeatTimer.current !== null) window.clearInterval(heartbeatTimer.current)
    heartbeatTimer.current = null
  }

  const setTyping = useCallback((active: boolean) => {
    const current = subscription.current
    if (!current) return

    clearTimer(typingTimer)
    const now = Date.now()
    if (!active || !typingActive.current || now - typingSentAt.current >= 2_000) {
      current.perform("typing", { active })
      typingSentAt.current = now
    }
    typingActive.current = active
    if (active) {
      const delay = Math.min(Math.max(config?.typingIdleMs || 3_000, 1_000), 4_000)
      typingTimer.current = window.setTimeout(() => setTyping(false), delay)
    }
  }, [config?.typingIdleMs])

  useEffect(() => {
    if (!conversationPublicId || !config) {
      setState(EMPTY_STATE)
      return
    }

    setState(EMPTY_STATE)
    const heartbeatEvery = Math.min(Math.max(config.heartbeatIntervalMs, 5_000), 30_000)
    let current: CableSubscription
    current = consumer.subscriptions.create(
      {
        channel: config.channel,
        conversation_public_id: conversationPublicId,
        session_id: session.current
      },
      {
        connected() {
          setState(previous => ({ ...previous, available: true }))
          current.perform("reconcile")
          current.perform("heartbeat")
          clearHeartbeat()
          heartbeatTimer.current = window.setInterval(() => current.perform("heartbeat"), heartbeatEvery)
        },
        disconnected() {
          clearHeartbeat()
          clearTimer(typingTimer)
          typingActive.current = false
          setState(EMPTY_STATE)
        },
        received(envelope: PresenceEnvelope) {
          if (!validEnvelope(envelope, conversationPublicId)) return

          setState({ available: true, online: envelope.online, typing: envelope.typing })
        },
        rejected() {
          clearHeartbeat()
          clearTimer(typingTimer)
          typingActive.current = false
          setState(EMPTY_STATE)
        }
      }
    )
    subscription.current = current

    return () => {
      clearHeartbeat()
      clearTimer(typingTimer)
      typingActive.current = false
      current.unsubscribe()
      if (subscription.current === current) subscription.current = null
    }
  }, [config?.channel, config?.heartbeatIntervalMs, consumer, conversationPublicId])

  return { ...state, setTyping }
}
