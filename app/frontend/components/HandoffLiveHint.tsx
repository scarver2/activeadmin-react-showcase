// app/frontend/components/HandoffLiveHint.tsx

import { createConsumer } from "@rails/actioncable"
import { useEffect, useState } from "react"

type Props = { itemId: string, version: number, refreshUrl: string }

// Live messages only announce invalidation; they never mutate work or grant approval.
export default function HandoffLiveHint({ itemId, version, refreshUrl }: Props) {
  const [connection, setConnection] = useState("connecting")
  const [changed, setChanged] = useState(false)
  useEffect(() => {
    const consumer = createConsumer()
    const subscription = consumer.subscriptions.create({ channel: "HandoffsChannel", item_id: itemId }, {
      connected() { setConnection("connected") },
      disconnected() { setConnection("unavailable") },
      rejected() { setConnection("unavailable") },
      received(hint: { version: number }) {
        if (hint.version > version) setChanged(true)
      }
    })
    return () => { subscription.unsubscribe(); consumer.disconnect() }
  }, [itemId, version])

  return <aside aria-label="Live work hints">
    <p role="status">{changed ? "Work changed. Refresh before acting." : `Live hints: ${connection}. Durable state remains available.`}</p>
    <a href={refreshUrl}>Refresh from Rails</a>
  </aside>
}
