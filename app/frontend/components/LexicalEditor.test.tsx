// app/frontend/components/LexicalEditor.test.tsx

import { render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"

import LexicalEditor, { handleEditorError } from "./LexicalEditor"

const persistedState = JSON.stringify({
  root: {
    children: [
      {
        children: [
          { detail: 0, format: 0, mode: "normal", style: "", text: "Saved draft", type: "text", version: 1 }
        ],
        direction: null,
        format: "",
        indent: 0,
        type: "paragraph",
        version: 1
      }
    ],
    direction: null,
    format: "",
    indent: 0,
    type: "root",
    version: 1
  }
})

const blankState = JSON.stringify({
  root: {
    children: [{ children: [], direction: null, format: "", indent: 0, type: "paragraph", version: 1 }],
    direction: null,
    format: "",
    indent: 0,
    type: "root",
    version: 1
  }
})

function renderEditor(state = persistedState) {
  return render(
    <LexicalEditor
      editorStateName="showcase_article[editor_state]"
      initialState={state}
    />
  )
}

describe("LexicalEditor", () => {
  it("hydrates submitted state and writes edits into the Rails form contract", async () => {
    const user = userEvent.setup()
    renderEditor()

    const editor = screen.getByRole("textbox", { name: "Article body" })
    expect(editor).toHaveTextContent("Saved draft")
    expect(screen.getByTestId("editor-state")).toHaveAttribute("name", "showcase_article[editor_state]")

    await user.click(editor)
    await user.keyboard(" plus edit")

    await waitFor(() => {
      expect(screen.getByTestId("editor-state").getAttribute("value")).toContain("plus edit")
    })
  })

  it("provides the complete accessible WYSIWYG toolbar", async () => {
    const user = userEvent.setup()
    renderEditor()
    const editor = screen.getByRole("textbox", { name: "Article body" })

    await user.click(editor)
    await user.click(screen.getByRole("button", { name: "Bold" }))
    await user.click(screen.getByRole("button", { name: "Italic" }))
    await user.click(screen.getByRole("button", { name: "Underline" }))
    expect(screen.getByRole("toolbar", { name: "Document formatting" })).toBeVisible()
    expect(screen.getByRole("combobox", { name: "Block style" })).toHaveValue("paragraph")
    expect(screen.getByRole("button", { name: "Bulleted list" })).toBeVisible()
    expect(screen.getByRole("button", { name: "Numbered list" })).toBeVisible()
    expect(screen.getByRole("button", { name: "Clear formatting" })).toBeVisible()
    expect(screen.getByRole("button", { name: "Undo" })).toBeVisible()
    expect(screen.getByRole("button", { name: "Redo" })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Bold" })).toHaveAttribute("aria-keyshortcuts", "Control+B Meta+B")
  })

  it("keeps toolbar commands harmless before the editor has a selection", async () => {
    const user = userEvent.setup()
    renderEditor()

    await user.selectOptions(screen.getByRole("combobox", { name: "Block style" }), "h2")
    await user.click(screen.getByRole("button", { name: "Clear formatting" }))

    expect(screen.getByRole("textbox", { name: "Article body" })).toHaveTextContent("Saved draft")
  })

  it("opens an accessible link editor and writes a link node into canonical state", async () => {
    const user = userEvent.setup()
    renderEditor()
    const editor = screen.getByRole("textbox", { name: "Article body" })

    await user.click(editor)
    await user.keyboard("{Control>}a{/Control}")
    await user.click(screen.getByRole("button", { name: "Insert or edit link" }))
    const url = screen.getByRole("textbox", { name: "Destination URL" })
    await user.clear(url)
    await user.type(url, "https://activeadmin.info")
    await user.click(screen.getByRole("button", { name: "Apply link" }))

    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).toContain("https://activeadmin.info"))

    await user.click(screen.getByRole("button", { name: "Insert or edit link" }))
    await user.click(screen.getByRole("button", { name: "Remove link" }))
    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).not.toContain("https://activeadmin.info"))

    await user.click(screen.getByRole("button", { name: "Insert or edit link" }))
    await user.clear(screen.getByRole("textbox", { name: "Destination URL" }))
    await user.click(screen.getByRole("button", { name: "Apply link" }))
    expect(screen.queryByRole("group", { name: "Link editor" })).not.toBeInTheDocument()
  })

  it("applies block and list formats and can clear them back to a paragraph", async () => {
    const user = userEvent.setup()
    renderEditor()
    const editor = screen.getByRole("textbox", { name: "Article body" })

    await user.click(editor)
    await user.keyboard("{Control>}a{/Control}")
    await user.selectOptions(screen.getByRole("combobox", { name: "Block style" }), "h2")
    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).toContain('"type":"heading"'))

    await user.selectOptions(screen.getByRole("combobox", { name: "Block style" }), "quote")
    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).toContain('"type":"quote"'))

    await user.selectOptions(screen.getByRole("combobox", { name: "Block style" }), "paragraph")
    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).toContain('"type":"paragraph"'))

    await user.click(screen.getByRole("button", { name: "Bulleted list" }))
    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).toContain('"listType":"bullet"'))

    await user.click(screen.getByRole("button", { name: "Numbered list" }))
    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).toContain('"listType":"number"'))

    await user.click(screen.getByRole("button", { name: "Clear formatting" }))
    await waitFor(() => expect(screen.getByTestId("editor-state").getAttribute("value")).toContain('"type":"paragraph"'))
  })

  it("exposes working undo and redo history controls", async () => {
    const user = userEvent.setup()
    renderEditor()
    const editor = screen.getByRole("textbox", { name: "Article body" })

    await user.click(editor)
    await user.keyboard(" history")
    await waitFor(() => expect(screen.getByRole("button", { name: "Undo" })).toBeEnabled())
    await user.click(screen.getByRole("button", { name: "Undo" }))
    await waitFor(() => expect(screen.getByRole("button", { name: "Redo" })).toBeEnabled())
    await user.click(screen.getByRole("button", { name: "Redo" }))
    await waitFor(() => {
      expect(editor).toHaveTextContent("Saved draft")
      expect(editor).toHaveTextContent("history")
    })
  })

  it("surfaces Lexical errors instead of persisting a corrupt document", () => {
    expect(() => handleEditorError(new Error("corrupt state"))).toThrow("corrupt state")
  })

  it("hydrates the server-normalized empty paragraph as an editable document", () => {
    renderEditor(blankState)
    const editor = screen.getByRole("textbox", { name: "Article body" })

    expect(editor).toHaveTextContent("")
    expect(editor).toHaveAttribute("contenteditable", "true")
    expect(screen.getByTestId("editor-state")).toHaveValue(blankState)
  })
})
