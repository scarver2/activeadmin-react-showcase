// app/frontend/components/CkeditorEditor.test.tsx

import { act, render, screen, waitFor } from "@testing-library/react"
import { vi } from "vitest"

const { create, editor } = vi.hoisted(() => {
  const changeListeners: Array<() => void> = []
  const editorDouble = {
    destroy: vi.fn(async () => undefined),
    getData: vi.fn(() => "<p>Edited safely</p>"),
    model: {
      document: {
        on: vi.fn((_event: string, callback: () => void) => changeListeners.push(callback))
      }
    }
  }

  return {
    create: vi.fn(async () => editorDouble),
    editor: Object.assign(editorDouble, { changeListeners })
  }
})

vi.mock("ckeditor5", () => ({
  Autoformat: class Autoformat {},
  BlockQuote: class BlockQuote {},
  Bold: class Bold {},
  ClassicEditor: { create },
  CodeBlock: class CodeBlock {},
  Essentials: class Essentials {},
  Heading: class Heading {},
  Italic: class Italic {},
  Link: class Link {},
  List: class List {},
  Paragraph: class Paragraph {},
  SelectAll: class SelectAll {}
}))

import CkeditorEditor, { ckeditorConfiguration } from "./CkeditorEditor"

describe("CkeditorEditor", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    editor.changeListeners.length = 0
    editor.getData.mockReturnValue("<p>Edited safely</p>")
    create.mockResolvedValue(editor)
    document.body.innerHTML = '<form><textarea id="article-body">Initial</textarea></form>'
  })

  it("enhances the Rails textarea with the bounded self-hosted GPL contract", async () => {
    render(<CkeditorEditor textareaId="article-body" />)

    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("Rich editor ready"))
    expect(create).toHaveBeenCalledWith(document.getElementById("article-body"), ckeditorConfiguration)
    expect(ckeditorConfiguration.licenseKey).toBe("GPL")
    expect((ckeditorConfiguration.toolbar as { items: string[] }).items).not.toContain("imageUpload")
  })

  it("synchronizes editor data on changes and form submission", async () => {
    render(<CkeditorEditor textareaId="article-body" />)
    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("Rich editor ready"))

    const textarea = document.getElementById("article-body") as HTMLTextAreaElement
    editor.getData.mockReturnValue("<h2>Changed</h2>")
    act(() => editor.changeListeners[0]?.())
    expect(textarea.value).toBe("<h2>Changed</h2>")

    editor.getData.mockReturnValue("<p>Submitted</p>")
    document.querySelector("form")?.dispatchEvent(new Event("submit"))
    expect(textarea.value).toBe("<p>Submitted</p>")
  })

  it("leaves the textarea usable when initialization fails", async () => {
    create.mockRejectedValueOnce(new Error("load failed"))
    render(<CkeditorEditor textareaId="article-body" />)

    expect(await screen.findByRole("alert")).toHaveTextContent("textarea fallback")
    expect(document.getElementById("article-body")).toBeInstanceOf(HTMLTextAreaElement)
  })

  it("reuses an in-flight initialization instead of creating a duplicate editor", async () => {
    render(
      <>
        <CkeditorEditor textareaId="article-body" />
        <CkeditorEditor textareaId="article-body" />
      </>
    )

    await waitFor(() => expect(screen.getAllByRole("status")).toHaveLength(2))
    expect(create).toHaveBeenCalledOnce()
  })

  it("keeps an early form submission harmless while initialization is pending", async () => {
    let resolveEditor: ((value: typeof editor) => void) | undefined
    create.mockImplementationOnce(() => new Promise((resolve) => { resolveEditor = resolve }))
    render(<CkeditorEditor textareaId="article-body" />)

    const textarea = document.getElementById("article-body") as HTMLTextAreaElement
    document.querySelector("form")?.dispatchEvent(new Event("submit"))
    expect(textarea.value).toBe("Initial")

    await act(async () => resolveEditor?.(editor))
  })

  it("fails accessibly when the host textarea contract is missing", () => {
    render(<CkeditorEditor textareaId="missing" />)

    expect(screen.getByRole("alert")).toHaveTextContent("textarea fallback")
    expect(create).not.toHaveBeenCalled()
  })

  it("destroys the editor for Turbo cache and component teardown without duplicates", async () => {
    const { unmount } = render(<CkeditorEditor textareaId="article-body" />)
    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("Rich editor ready"))

    document.dispatchEvent(new Event("turbo:before-cache"))
    expect(editor.destroy).toHaveBeenCalledOnce()
    unmount()
    expect(editor.destroy).toHaveBeenCalledOnce()
  })

  it("destroys an editor that finishes initialization after unmount", async () => {
    let resolveEditor: ((value: typeof editor) => void) | undefined
    create.mockImplementationOnce(() => new Promise((resolve) => { resolveEditor = resolve }))
    const { unmount } = render(<CkeditorEditor textareaId="article-body" />)
    unmount()

    await act(async () => resolveEditor?.(editor))
    expect(editor.destroy).toHaveBeenCalledOnce()
  })

  it("contains a late initialization failure after unmount", async () => {
    let rejectEditor: ((error: Error) => void) | undefined
    create.mockImplementationOnce(() => new Promise((_resolve, reject) => { rejectEditor = reject }))
    const { unmount } = render(<CkeditorEditor textareaId="article-body" />)
    unmount()

    await act(async () => rejectEditor?.(new Error("late failure")))
    expect(screen.queryByRole("alert")).not.toBeInTheDocument()
  })
})
