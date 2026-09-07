// app/frontend/components/FileImageManager.tsx

import { FormEvent, useState } from "react"

export type ManagedAsset = {
  id: number
  title: string
  filename: string
  contentType: string
  byteSize: number
  previewKind: "image" | "download"
  url: string
  deleteUrl: string
}

type Props = { assets: ManagedAsset[], createUrl: string, resetUrl: string }

const allowedTypes = ["image/png", "image/jpeg", "application/pdf", "text/plain"]
const maximumBytes = 5 * 1024 * 1024

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

export default function FileImageManager({ assets: initialAssets, createUrl, resetUrl }: Props) {
  const [assets, setAssets] = useState(initialAssets)
  const [title, setTitle] = useState("")
  const [file, setFile] = useState<File | null>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function upload(event: FormEvent) {
    event.preventDefault()
    if (!file) return
    if (!allowedTypes.includes(file.type)) return setError("Choose a PNG, JPEG, PDF, or text file.")
    if (file.size > maximumBytes) return setError("Choose a file no larger than 5 MB.")

    const body = new FormData()
    body.append("title", title.trim())
    body.append("file", file)
    await safely(async () => {
      const response = await fetch(createUrl, {
        method: "POST", credentials: "same-origin", headers: { Accept: "application/json", "X-CSRF-Token": csrfToken() }, body
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Asset could not be uploaded")
      setAssets((current) => [...current, payload])
      setTitle("")
      setFile(null)
    })
  }

  async function remove(asset: ManagedAsset) {
    await safely(async () => {
      const response = await fetch(asset.deleteUrl, {
        method: "DELETE", credentials: "same-origin", headers: { Accept: "application/json", "X-CSRF-Token": csrfToken() }
      })
      if (!response.ok) throw new Error("Asset could not be deleted")
      setAssets((current) => current.filter((candidate) => candidate.id !== asset.id))
    })
  }

  async function reset() {
    await safely(async () => {
      const response = await fetch(resetUrl, {
        method: "POST", credentials: "same-origin", headers: { Accept: "application/json", "X-CSRF-Token": csrfToken() }
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Assets could not be reset")
      setAssets(payload)
    })
  }

  async function safely(action: () => Promise<void>) {
    setPending(true)
    setError(null)
    try {
      await action()
    } catch (commandError) {
      setError((commandError as Error).message)
    } finally {
      setPending(false)
    }
  }

  return (
    <section className="space-y-6" data-testid="file-image-manager">
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3" aria-label="Managed assets">
        {assets.length === 0 && <p>No assets yet. Upload a safe synthetic file.</p>}
        {assets.map((asset) => (
          <article className="rounded-lg border bg-white p-4 dark:bg-gray-800" data-asset-id={asset.id} key={asset.id}>
            {asset.previewKind === "image" ? (
              <img alt={`${asset.title} preview`} className="h-40 w-full rounded object-contain" src={asset.url} />
            ) : (
              <a className="text-indigo-600 underline" href={asset.url}>Open {asset.filename}</a>
            )}
            <h2 className="mt-3 font-semibold">{asset.title}</h2>
            <p className="text-sm text-gray-500">{asset.contentType} · {asset.byteSize} bytes</p>
            <button className="mt-3 rounded border px-3 py-1" disabled={pending} onClick={() => void remove(asset)} type="button">Delete {asset.title}</button>
          </article>
        ))}
      </div>

      <form className="space-y-3 rounded border p-4" onSubmit={(event) => void upload(event)}>
        <h2 className="font-semibold">Upload a synthetic asset</h2>
        <label className="block" htmlFor="asset-title">Title</label>
        <input id="asset-title" maxLength={80} onChange={(event) => setTitle(event.target.value)} required value={title} />
        <label className="block" htmlFor="asset-file">File</label>
        <input accept={allowedTypes.join(",")} id="asset-file" onChange={(event) => setFile(event.target.files?.[0] || null)} required type="file" />
        {file && <p data-testid="selected-file">Selected: {file.name} · {file.type || "unknown type"} · {file.size} bytes</p>}
        <div className="flex gap-2">
          <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={pending || !file || title.trim().length === 0} type="submit">Upload asset</button>
          <button className="rounded border px-4 py-2" disabled={pending} onClick={() => void reset()} type="button">Reset synthetic assets</button>
        </div>
      </form>
      {error && <p className="text-red-700" role="alert">{error}</p>}

      <div className="grid gap-4 lg:grid-cols-3">
        <Guidance title="Ruby"><code>ShowcaseAsset.create!(title:, file:)</code><p>Active Storage and model validation own persistence and safety.</p></Guidance>
        <Guidance title="JavaScript"><code>FormData → authenticated Rails command</code><p>The island shows selection, progress, errors, previews, and reset.</p></Guidance>
        <Guidance title="Architecture"><p>Browser → Rails validation → Active Storage disk service on persistent Kamal storage.</p></Guidance>
      </div>
    </section>
  )
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><div className="mt-2 space-y-2 text-sm">{children}</div></section>
}
