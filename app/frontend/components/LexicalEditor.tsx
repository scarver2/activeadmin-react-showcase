// app/frontend/components/LexicalEditor.tsx

import { $generateHtmlFromNodes } from "@lexical/html"
import { AutoFocusPlugin } from "@lexical/react/LexicalAutoFocusPlugin"
import { LexicalComposer } from "@lexical/react/LexicalComposer"
import { ContentEditable } from "@lexical/react/LexicalContentEditable"
import { LexicalErrorBoundary } from "@lexical/react/LexicalErrorBoundary"
import { HistoryPlugin } from "@lexical/react/LexicalHistoryPlugin"
import { useLexicalComposerContext } from "@lexical/react/LexicalComposerContext"
import { OnChangePlugin } from "@lexical/react/LexicalOnChangePlugin"
import { RichTextPlugin } from "@lexical/react/LexicalRichTextPlugin"
import { FORMAT_TEXT_COMMAND, type EditorState, type LexicalEditor as Editor } from "lexical"
import { useState } from "react"

export type LexicalEditorProps = {
  editorStateName: string
  initialHtml: string
  initialState: string
  renderedHtmlName: string
}

export function handleEditorError(error: Error): never {
  throw error
}

function Toolbar() {
  const [editor] = useLexicalComposerContext()

  function format(format: "bold" | "italic") {
    editor.dispatchCommand(FORMAT_TEXT_COMMAND, format)
  }

  return (
    <div aria-label="Formatting" className="lexical-toolbar" role="toolbar">
      <button onClick={() => format("bold")} type="button">
        Bold
      </button>
      <button onClick={() => format("italic")} type="button">
        Italic
      </button>
    </div>
  )
}

function PersistencePlugin({
  onDocumentChange
}: {
  onDocumentChange: (editorState: EditorState, editor: Editor) => void
}) {
  return <OnChangePlugin ignoreSelectionChange onChange={onDocumentChange} />
}

export default function LexicalEditor({
  editorStateName,
  initialHtml,
  initialState,
  renderedHtmlName
}: LexicalEditorProps) {
  const [editorState, setEditorState] = useState(initialState)
  const [renderedHtml, setRenderedHtml] = useState(initialHtml)

  function persistDocument(nextState: EditorState, editor: Editor) {
    setEditorState(JSON.stringify(nextState.toJSON()))
    nextState.read(() => setRenderedHtml($generateHtmlFromNodes(editor)))
  }

  return (
    <section aria-label="Rich text editor" className="lexical-editor" data-testid="lexical-editor">
      <input data-testid="editor-state" name={editorStateName} type="hidden" value={editorState} />
      <input data-testid="rendered-html" name={renderedHtmlName} type="hidden" value={renderedHtml} />
      <LexicalComposer
        initialConfig={{
          editorState: initialState,
          namespace: "ShowcaseArticle",
          onError: handleEditorError,
          theme: {
            paragraph: "lexical-paragraph",
            text: { bold: "lexical-bold", italic: "lexical-italic" }
          }
        }}
      >
        <Toolbar />
        <div className="lexical-surface">
          <RichTextPlugin
            ErrorBoundary={LexicalErrorBoundary}
            contentEditable={<ContentEditable aria-label="Article body" className="lexical-content-editable" />}
            placeholder={<div className="lexical-placeholder">Write the article body…</div>}
          />
          <HistoryPlugin />
          <AutoFocusPlugin />
          <PersistencePlugin onDocumentChange={persistDocument} />
        </div>
      </LexicalComposer>
    </section>
  )
}
