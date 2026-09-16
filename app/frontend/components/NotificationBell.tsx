// app/frontend/components/NotificationBell.tsx

import { createConsumer } from "@rails/actioncable"
import { useEffect, useRef, useState } from "react"

type Props = {
  activityCenterUrl: string
  initialUnreadCount: number
  latestSequence: number
}

type NotificationEnvelope = {
  type: "notification"
  notification: { read: boolean, sequence: number }
}

type UnreadCountEnvelope = {
  type: "unread_count"
  latestSequence: number
  unreadCount: number
}

type UnreadDeltaEvent = CustomEvent<{ delta: number }>

export const UNREAD_DELTA_EVENT = "activity-center:unread-delta"

function boundedCount(value: number) {
  return Math.max(0, value)
}

export default function NotificationBell({ activityCenterUrl, initialUnreadCount, latestSequence: initialSequence }: Props) {
  const [unreadCount, setUnreadCount] = useState(() => boundedCount(initialUnreadCount))
  const latestSequence = useRef(initialSequence)
  const consumer = useRef(createConsumer())

  useEffect(() => {
    const subscription = consumer.current.subscriptions.create(
      { channel: "ActivityCenterChannel", after_sequence: latestSequence.current },
      {
        received: (envelope: NotificationEnvelope | UnreadCountEnvelope) => {
          if (envelope.type === "unread_count") {
            latestSequence.current = Math.max(latestSequence.current, envelope.latestSequence)
            setUnreadCount(boundedCount(envelope.unreadCount))
            return
          }

          if (envelope.notification.sequence <= latestSequence.current) return

          latestSequence.current = envelope.notification.sequence
          if (!envelope.notification.read) setUnreadCount((current) => current + 1)
        }
      }
    )
    const applyOptimisticDelta = (event: Event) => {
      const { delta } = (event as UnreadDeltaEvent).detail
      setUnreadCount((current) => boundedCount(current + delta))
    }
    window.addEventListener(UNREAD_DELTA_EVENT, applyOptimisticDelta)

    return () => {
      window.removeEventListener(UNREAD_DELTA_EVENT, applyOptimisticDelta)
      subscription.unsubscribe()
      consumer.current.disconnect()
    }
  }, [])

  const label = `Notifications, ${unreadCount} unread`

  return (
    <a
      aria-label={label}
      className="notification-bell"
      data-testid="notification-bell"
      href={activityCenterUrl}
      title={label}
    >
      <svg aria-hidden="true" fill="none" viewBox="0 0 24 24">
        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
      </svg>
      {unreadCount > 0 && <span aria-hidden="true" className="notification-bell__badge">{unreadCount > 99 ? "99+" : unreadCount}</span>}
    </a>
  )
}
