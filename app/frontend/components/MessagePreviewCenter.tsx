// app/frontend/components/MessagePreviewCenter.tsx

import { useState } from "react"

type Attachment = { filename: string, id: number, kind: "download" | "image" | "oversized" | "pdf", size: number, url?: string }
type Message = { attachments: Attachment[], htmlBody: string, id: number, recipient: string, sender: string, subject: string, textBody: string }
export type MessagePreviewCenterProps = { messages: Message[] }

export default function MessagePreviewCenter({ messages }: MessagePreviewCenterProps) {
  const [messageId, setMessageId] = useState(messages[0]?.id)
  const message = messages.find((item) => item.id === messageId)
  const [bodyTab, setBodyTab] = useState<"html" | "text">("html")
  const [attachmentId, setAttachmentId] = useState<number | null>(null)
  const attachment = message?.attachments.find((item) => item.id === attachmentId)

  if (!message) return <p>No development messages are available.</p>
  return <section className="grid gap-5 lg:grid-cols-[18rem_1fr]" data-testid="message-preview-center">
    <nav aria-label="Development messages"><ul>{messages.map((item) => <li key={item.id}><button aria-current={item.id === message.id ? "page" : undefined} className="w-full rounded border p-3 text-left" onClick={() => { setMessageId(item.id); setAttachmentId(null) }} type="button">{item.subject}<span className="block text-sm">To {item.recipient}</span></button></li>)}</ul></nav>
    <article className="space-y-4"><header><h2 className="text-xl font-semibold">{message.subject}</h2><p>{message.sender} → {message.recipient}</p></header>
      <div role="tablist" aria-label="Message body"><button aria-selected={bodyTab === "html"} onClick={() => setBodyTab("html")} role="tab" type="button">HTML</button><button aria-selected={bodyTab === "text"} onClick={() => setBodyTab("text")} role="tab" type="button">Text</button></div>
      {bodyTab === "html" ? <iframe sandbox="" title="Sanitized email HTML" srcDoc={message.htmlBody} className="h-64 w-full border"/> : <pre className="whitespace-pre-wrap">{message.textBody}</pre>}
      <section><h3 className="font-semibold">Attachments</h3><ul>{message.attachments.map((item) => <li key={item.id}><button disabled={item.kind === "oversized"} onClick={() => setAttachmentId(item.id)} type="button">Preview {item.filename}</button>{item.url && <a className="ml-3 underline" href={item.url}>Download/open</a>}{item.kind === "oversized" && <span> — too large to preview</span>}</li>)}</ul></section>
      {attachment && <AttachmentPreview attachment={attachment}/>} 
    </article>
  </section>
}

function AttachmentPreview({ attachment }: { attachment: Attachment }) {
  if (!attachment.url) return <p role="alert">Attachment is missing or unsupported.</p>
  if (attachment.kind === "image") return <img alt={`Preview of ${attachment.filename}`} className="max-h-96" src={attachment.url}/>
  if (attachment.kind === "pdf") return <iframe className="h-96 w-full border" src={attachment.url} title={`PDF preview of ${attachment.filename}`}/>
  return <p>Office documents are downloaded rather than executed in the browser. <a href={attachment.url}>Download {attachment.filename}</a></p>
}
