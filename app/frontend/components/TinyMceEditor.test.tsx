// app/frontend/components/TinyMceEditor.test.tsx

import { act, render, screen, waitFor } from "@testing-library/react"
import { vi } from "vitest"

const { editor, init } = vi.hoisted(() => {
  const editorDouble = {
    on: vi.fn((_event: string, callback: () => void) => callback()),
    remove: vi.fn(),
    save: vi.fn()
  }
  const initDouble = vi.fn(async (configuration: { setup: (instance: typeof editorDouble) => void }) => {
    configuration.setup(editorDouble)
    return [editorDouble]
  })

  return { editor: editorDouble, init: initDouble }
})

vi.mock("tinymce", () => ({ default: { init } }))
vi.mock("tinymce/icons/default", () => ({}))
vi.mock("tinymce/models/dom", () => ({}))
vi.mock("tinymce/plugins/autolink", () => ({}))
vi.mock("tinymce/plugins/code", () => ({}))
vi.mock("tinymce/plugins/link", () => ({}))
vi.mock("tinymce/plugins/lists", () => ({}))
vi.mock("tinymce/plugins/wordcount", () => ({}))
vi.mock("tinymce/themes/silver", () => ({}))

import TinyMceEditor from "./TinyMceEditor"

describe("TinyMceEditor", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    editor.on.mockImplementation((_event: string, callback: () => void) => callback())
    init.mockImplementation(async (configuration: { setup: (instance: typeof editor) => void }) => {
      configuration.setup(editor)
      return [editor]
    })
    document.body.innerHTML = '<form><textarea id="article-body"></textarea></form>'
  })

  it("enhances the Rails textarea with the bounded, self-hosted editor contract", async () => {
    const { unmount } = render(<TinyMceEditor textareaId="article-body" />)

    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("Rich editor ready"))
    expect(init).toHaveBeenCalledWith(expect.objectContaining({
      automatic_uploads: false,
      license_key: "gpl",
      paste_data_images: false,
      plugins: "autolink code link lists wordcount",
      target: document.getElementById("article-body")
    }))

    document.querySelector("form")?.dispatchEvent(new Event("submit"))
    expect(editor.save).toHaveBeenCalledOnce()

    unmount()
    expect(editor.remove).toHaveBeenCalledOnce()
  })

  it("leaves the textarea usable when TinyMCE cannot initialize", async () => {
    init.mockRejectedValueOnce(new Error("load failed"))
    render(<TinyMceEditor textareaId="article-body" />)

    expect(await screen.findByRole("alert")).toHaveTextContent("plain-textarea fallback")
    expect(document.getElementById("article-body")).toBeInstanceOf(HTMLTextAreaElement)
  })

  it("fails accessibly when the host textarea contract is missing", () => {
    render(<TinyMceEditor textareaId="missing" />)

    expect(screen.getByRole("alert")).toHaveTextContent("plain-textarea fallback")
    expect(init).not.toHaveBeenCalled()
  })

  it("also enhances a standalone textarea without assuming a parent form", async () => {
    document.body.innerHTML = '<textarea id="article-body"></textarea>'
    render(<TinyMceEditor textareaId="article-body" />)

    await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("Rich editor ready"))
    expect(init).toHaveBeenCalledOnce()
  })

  it("does not initialize after an immediate unmount", async () => {
    const { unmount } = render(<TinyMceEditor textareaId="article-body" />)
    unmount()

    await act(async () => Promise.resolve())
    expect(init).not.toHaveBeenCalled()
  })

  it("removes an editor that finishes initialization after unmount", async () => {
    let finishInitialization: ((editors: Array<typeof editor>) => void) | undefined
    init.mockImplementationOnce((configuration: { setup: (instance: typeof editor) => void }) => {
      configuration.setup(editor)
      return new Promise((resolve) => { finishInitialization = resolve })
    })
    const { unmount } = render(<TinyMceEditor textareaId="article-body" />)
    await waitFor(() => expect(init).toHaveBeenCalledOnce())

    unmount()
    await act(async () => finishInitialization?.([editor]))

    expect(editor.remove).toHaveBeenCalledTimes(2)
  })

  it("contains a late initialization failure after unmount", async () => {
    let rejectInitialization: ((error: Error) => void) | undefined
    init.mockImplementationOnce(() => new Promise((_resolve, reject) => { rejectInitialization = reject }))
    const { unmount } = render(<TinyMceEditor textareaId="article-body" />)
    await waitFor(() => expect(init).toHaveBeenCalledOnce())

    unmount()
    await act(async () => rejectInitialization?.(new Error("late failure")))

    expect(screen.queryByRole("alert")).not.toBeInTheDocument()
  })

  it("ignores a late ready callback after unmount", async () => {
    let ready: (() => void) | undefined
    editor.on.mockImplementationOnce((_event: string, callback: () => void) => { ready = callback })
    const { unmount } = render(<TinyMceEditor textareaId="article-body" />)
    await waitFor(() => expect(init).toHaveBeenCalledOnce())
    unmount()

    act(() => ready?.())

    expect(screen.queryByText("Rich editor ready")).not.toBeInTheDocument()
  })
})
