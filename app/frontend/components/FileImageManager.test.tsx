// app/frontend/components/FileImageManager.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import FileImageManager from "./FileImageManager"
import type { ManagedAsset } from "./FileImageManager"

const image: ManagedAsset = {
  id: 1,
  title: "Bluebonnet product sample",
  filename: "bluebonnet.png",
  contentType: "image/png",
  byteSize: 68,
  previewKind: "image",
  url: "/rails/active_storage/image",
  deleteUrl: "/admin/showcase_assets/1"
}

const download: ManagedAsset = {
  ...image,
  id: 2,
  title: "Synthetic fulfillment notes",
  filename: "notes.txt",
  contentType: "text/plain",
  previewKind: "download",
  url: "/rails/active_storage/text",
  deleteUrl: "/admin/showcase_assets/2"
}

const props = { assets: [image, download], createUrl: "/admin/showcase_assets" }

function choose(file: File, title = "Uploaded fixture") {
  fireEvent.change(screen.getByLabelText("Title"), { target: { value: title } })
  fireEvent.change(screen.getByLabelText("File"), { target: { files: [file] } })
}

describe("FileImageManager", () => {
  beforeEach(() => vi.stubGlobal("fetch", vi.fn()))

  it("renders image and download previews with the complete page contract", () => {
    render(<FileImageManager {...props} />)

    expect(screen.getByAltText("Bluebonnet product sample preview")).toHaveAttribute("src", image.url)
    expect(screen.getByRole("link", { name: "Open notes.txt" })).toHaveAttribute("href", download.url)
    expect(screen.getByText("Ruby")).not.toBeNull()
    expect(screen.getByText("JavaScript")).not.toBeNull()
    expect(screen.getByText("Architecture")).not.toBeNull()
  })

  it("shows an empty state and ignores a submitted form without a file", () => {
    render(<FileImageManager {...props} assets={[]} />)
    expect(screen.getByText("No assets yet. Upload a safe synthetic file.")).not.toBeNull()

    fireEvent.submit(screen.getByRole("button", { name: "Upload asset" }).closest("form")!)
    expect(fetch).not.toHaveBeenCalled()
  })

  it("previews selection and rejects unsupported or oversized files locally", () => {
    render(<FileImageManager {...props} />)
    choose(new File(["unsafe"], "unsafe.bin", { type: "application/octet-stream" }))
    expect(screen.getByTestId("selected-file")).toHaveTextContent("unsafe.bin")
    fireEvent.submit(screen.getByRole("button", { name: "Upload asset" }).closest("form")!)
    expect(screen.getByRole("alert")).toHaveTextContent("Choose a PNG, JPEG, PDF, or text file.")

    choose(new File([new Uint8Array((5 * 1024 * 1024) + 1)], "large.txt", { type: "text/plain" }))
    fireEvent.submit(screen.getByRole("button", { name: "Upload asset" }).closest("form")!)
    expect(screen.getByRole("alert")).toHaveTextContent("Choose a file no larger than 5 MB.")
  })

  it("uploads FormData with CSRF protection and appends the server record", async () => {
    const meta = document.createElement("meta")
    meta.name = "csrf-token"
    meta.content = "csrf-test"
    document.head.append(meta)
    const uploaded = { ...download, id: 3, title: "Uploaded fixture" }
    const fetchMock = vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(uploaded), { status: 201 }))
    render(<FileImageManager {...props} />)
    choose(new File(["safe"], "safe.txt", { type: "text/plain" }))

    fireEvent.submit(screen.getByRole("button", { name: "Upload asset" }).closest("form")!)

    expect(await screen.findByText("Uploaded fixture")).not.toBeNull()
    expect(fetchMock).toHaveBeenCalledWith(props.createUrl, expect.objectContaining({
      body: expect.any(FormData), headers: expect.objectContaining({ "X-CSRF-Token": "csrf-test" }), method: "POST"
    }))
    expect(screen.getByLabelText("Title")).toHaveProperty("value", "")
    meta.remove()
  })

  it("reports explicit and generic upload errors", async () => {
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ error: "Upload denied" }), { status: 422 }))
    render(<FileImageManager {...props} />)
    choose(new File(["safe"], "safe.txt", { type: "text/plain" }))
    fireEvent.submit(screen.getByRole("button", { name: "Upload asset" }).closest("form")!)
    expect(await screen.findByRole("alert")).toHaveTextContent("Upload denied")

    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    fireEvent.submit(screen.getByRole("button", { name: "Upload asset" }).closest("form")!)
    expect(await screen.findByRole("alert")).toHaveTextContent("Asset could not be uploaded")
  })

  it("cancels or confirms accessible asset deletion and reports failure", async () => {
    const fetchMock = vi.mocked(fetch)
    render(<FileImageManager {...props} />)

    fireEvent.click(screen.getByRole("button", { name: `Delete ${image.title}` }))
    const dialog = screen.getByRole("dialog", { name: `Delete ${image.title}?` })
    expect(dialog).toHaveAttribute("aria-modal", "true")
    expect(screen.getByRole("button", { name: "Cancel" })).toHaveFocus()
    fireEvent.keyDown(dialog, { key: "Tab" })
    expect(screen.getByRole("dialog")).not.toBeNull()
    fireEvent.keyDown(dialog, { key: "Escape" })
    expect(screen.queryByRole("dialog")).toBeNull()

    fireEvent.click(screen.getByRole("button", { name: `Delete ${image.title}` }))
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }))
    expect(fetchMock).not.toHaveBeenCalled()
    expect(screen.queryByRole("dialog")).toBeNull()

    fetchMock.mockResolvedValueOnce(new Response(null, { status: 204 }))
    fireEvent.click(screen.getByRole("button", { name: `Delete ${image.title}` }))
    fireEvent.click(screen.getByRole("button", { name: "Delete asset" }))
    await waitFor(() => expect(screen.queryByText(image.title)).toBeNull())

    fetchMock.mockResolvedValueOnce(new Response(null, { status: 500 }))
    fireEvent.click(screen.getByRole("button", { name: `Delete ${download.title}` }))
    fireEvent.click(screen.getByRole("button", { name: "Delete asset" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Asset could not be deleted")
  })

  it("shows unknown type for a file without browser metadata", () => {
    render(<FileImageManager {...props} />)
    choose(new File(["unknown"], "unknown.txt"))
    expect(screen.getByTestId("selected-file")).toHaveTextContent("unknown type")

    fireEvent.change(screen.getByLabelText("File"), { target: { files: [] } })
    expect(screen.queryByTestId("selected-file")).toBeNull()
  })

})
