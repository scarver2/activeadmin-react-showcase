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

function renderEditor(state = persistedState, html = "<p>Saved draft</p>") {
  return render(
    <LexicalEditor
      editorStateName="showcase_article[editor_state]"
      initialHtml={html}
      initialState={state}
      renderedHtmlName="showcase_article[rendered_html]"
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
    expect(screen.getByTestId("rendered-html")).toHaveValue("<p>Saved draft</p>")

    await user.click(editor)
    await user.keyboard(" plus edit")

    await waitFor(() => {
      expect(screen.getByTestId("editor-state").getAttribute("value")).toContain("plus edit")
      expect(screen.getByTestId("rendered-html").getAttribute("value")).toContain("plus edit")
    })
  })

  it("provides application-owned bold and italic formatting controls", async () => {
    const user = userEvent.setup()
    renderEditor()
    const editor = screen.getByRole("textbox", { name: "Article body" })

    await user.click(editor)
    await user.click(screen.getByRole("button", { name: "Bold" }))
    await user.click(screen.getByRole("button", { name: "Italic" }))
    expect(screen.getByRole("toolbar", { name: "Formatting" })).toBeVisible()
  })

  it("surfaces Lexical errors instead of persisting a corrupt document", () => {
    expect(() => handleEditorError(new Error("corrupt state"))).toThrow("corrupt state")
  })
})
