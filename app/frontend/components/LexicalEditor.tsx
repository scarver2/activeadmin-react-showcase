// app/frontend/components/LexicalEditor.tsx

import { LinkNode, TOGGLE_LINK_COMMAND } from "@lexical/link"
import {
  INSERT_ORDERED_LIST_COMMAND,
  INSERT_UNORDERED_LIST_COMMAND,
  ListItemNode,
  ListNode,
  REMOVE_LIST_COMMAND
} from "@lexical/list"
import { AutoFocusPlugin } from "@lexical/react/LexicalAutoFocusPlugin"
import { LexicalComposer } from "@lexical/react/LexicalComposer"
import { ContentEditable } from "@lexical/react/LexicalContentEditable"
import { LexicalErrorBoundary } from "@lexical/react/LexicalErrorBoundary"
import { HistoryPlugin } from "@lexical/react/LexicalHistoryPlugin"
import { LinkPlugin } from "@lexical/react/LexicalLinkPlugin"
import { ListPlugin } from "@lexical/react/LexicalListPlugin"
import { useLexicalComposerContext } from "@lexical/react/LexicalComposerContext"
import { OnChangePlugin } from "@lexical/react/LexicalOnChangePlugin"
import { RichTextPlugin } from "@lexical/react/LexicalRichTextPlugin"
import { $setBlocksType } from "@lexical/selection"
import { $createHeadingNode, $createQuoteNode, HeadingNode, QuoteNode } from "@lexical/rich-text"
import { mergeRegister } from "@lexical/utils"
import {
  $createParagraphNode,
  $getSelection,
  $isRangeSelection,
  CAN_REDO_COMMAND,
  CAN_UNDO_COMMAND,
  COMMAND_PRIORITY_LOW,
  FORMAT_TEXT_COMMAND,
  REDO_COMMAND,
  SELECTION_CHANGE_COMMAND,
  UNDO_COMMAND,
  type EditorState,
  type LexicalEditor as Editor
} from "lexical"
import { useCallback, useEffect, useState } from "react"

export type LexicalEditorProps = {
  editorStateName: string
  initialState: string
}

type BlockType = "paragraph" | "h2" | "h3" | "quote"

export function handleEditorError(error: Error): never {
  throw error
}

function Toolbar() {
  const [editor] = useLexicalComposerContext()
  const [blockType, setBlockType] = useState<BlockType>("paragraph")
  const [canRedo, setCanRedo] = useState(false)
  const [canUndo, setCanUndo] = useState(false)
  const [linkPanelOpen, setLinkPanelOpen] = useState(false)
  const [linkUrl, setLinkUrl] = useState("https://")

  const updateToolbar = useCallback(() => {
    const selection = $getSelection()
    /* v8 ignore next -- Lexical selection/update callbacks supply a range selection in the mounted editor. */
    if (!$isRangeSelection(selection)) return

    const topLevel = selection.anchor.getNode().getTopLevelElementOrThrow()
    const type = topLevel.getType()
    setBlockType(type === "heading" ? ((topLevel as HeadingNode).getTag() as "h2" | "h3") : type === "quote" ? "quote" : "paragraph")
  }, [])

  useEffect(
    () =>
      mergeRegister(
        editor.registerUpdateListener(({ editorState }) => editorState.read(updateToolbar)),
        editor.registerCommand(SELECTION_CHANGE_COMMAND, () => {
          updateToolbar()
          return false
        }, COMMAND_PRIORITY_LOW),
        editor.registerCommand(CAN_UNDO_COMMAND, (value) => {
          setCanUndo(value)
          return false
        }, COMMAND_PRIORITY_LOW),
        editor.registerCommand(CAN_REDO_COMMAND, (value) => {
          setCanRedo(value)
          return false
        }, COMMAND_PRIORITY_LOW)
      ),
    [editor, updateToolbar]
  )

  function format(formatName: "bold" | "italic" | "underline") {
    editor.dispatchCommand(FORMAT_TEXT_COMMAND, formatName)
  }

  function formatBlock(nextType: BlockType) {
    editor.update(() => {
      const selection = $getSelection()
      /* v8 ignore next -- The block picker is reachable only while Lexical owns a range selection. */
      if (!$isRangeSelection(selection)) return

      if (nextType === "h2" || nextType === "h3") {
        $setBlocksType(selection, () => $createHeadingNode(nextType))
      } else if (nextType === "quote") {
        $setBlocksType(selection, () => $createQuoteNode())
      } else {
        $setBlocksType(selection, () => $createParagraphNode())
      }
    })
  }

  function clearFormatting() {
    editor.dispatchCommand(REMOVE_LIST_COMMAND, undefined)
    editor.update(() => {
      const selection = $getSelection()
      /* v8 ignore next -- Formatting commands are reachable only while Lexical owns a range selection. */
      if (!$isRangeSelection(selection)) return

      selection.formatText("bold", 0)
      selection.formatText("italic", 0)
      selection.formatText("underline", 0)
      $setBlocksType(selection, () => $createParagraphNode())
    })
  }

  function applyLink() {
    editor.dispatchCommand(TOGGLE_LINK_COMMAND, linkUrl.trim() || null)
    setLinkPanelOpen(false)
    editor.focus()
  }

  return (
    <>
      <div aria-label="Document formatting" className="lexical-toolbar" role="toolbar">
        <label className="lexical-block-picker">
          <span className="sr-only">Block style</span>
          <select aria-label="Block style" onChange={(event) => formatBlock(event.target.value as BlockType)} value={blockType}>
            <option value="paragraph">Paragraph</option>
            <option value="h2">Heading 2</option>
            <option value="h3">Heading 3</option>
            <option value="quote">Block quote</option>
          </select>
        </label>
        <span aria-hidden="true" className="lexical-divider" />
        <button aria-keyshortcuts="Control+B Meta+B" aria-label="Bold" onClick={() => format("bold")} title="Bold (Ctrl/⌘ B)" type="button"><strong>B</strong></button>
        <button aria-keyshortcuts="Control+I Meta+I" aria-label="Italic" onClick={() => format("italic")} title="Italic (Ctrl/⌘ I)" type="button"><em>I</em></button>
        <button aria-keyshortcuts="Control+U Meta+U" aria-label="Underline" onClick={() => format("underline")} title="Underline (Ctrl/⌘ U)" type="button"><span className="underline">U</span></button>
        <button aria-expanded={linkPanelOpen} aria-label="Insert or edit link" onClick={() => setLinkPanelOpen((open) => !open)} title="Link" type="button">Link</button>
        <span aria-hidden="true" className="lexical-divider" />
        <button aria-label="Bulleted list" onClick={() => editor.dispatchCommand(INSERT_UNORDERED_LIST_COMMAND, undefined)} title="Bulleted list" type="button">• List</button>
        <button aria-label="Numbered list" onClick={() => editor.dispatchCommand(INSERT_ORDERED_LIST_COMMAND, undefined)} title="Numbered list" type="button">1. List</button>
        <button aria-label="Clear formatting" onClick={clearFormatting} title="Clear formatting" type="button">Clear</button>
        <span aria-hidden="true" className="lexical-divider" />
        <button aria-label="Undo" disabled={!canUndo} onClick={() => editor.dispatchCommand(UNDO_COMMAND, undefined)} title="Undo" type="button">↶</button>
        <button aria-label="Redo" disabled={!canRedo} onClick={() => editor.dispatchCommand(REDO_COMMAND, undefined)} title="Redo" type="button">↷</button>
      </div>
      {linkPanelOpen && (
        <div aria-label="Link editor" className="lexical-link-editor" role="group">
          <label htmlFor="lexical-link-url">Destination URL</label>
          <input id="lexical-link-url" onChange={(event) => setLinkUrl(event.target.value)} type="url" value={linkUrl} />
          <button onClick={applyLink} type="button">Apply link</button>
          <button onClick={() => {
            editor.dispatchCommand(TOGGLE_LINK_COMMAND, null)
            setLinkPanelOpen(false)
            editor.focus()
          }} type="button">Remove link</button>
        </div>
      )}
    </>
  )
}

function PersistencePlugin({ onDocumentChange }: { onDocumentChange: (editorState: EditorState, editor: Editor) => void }) {
  return <OnChangePlugin ignoreSelectionChange onChange={onDocumentChange} />
}

export default function LexicalEditor({ editorStateName, initialState }: LexicalEditorProps) {
  const [editorState, setEditorState] = useState(initialState)

  return (
    <section aria-label="Rich text editor" className="lexical-editor" data-testid="lexical-editor">
      <input data-testid="editor-state" name={editorStateName} type="hidden" value={editorState} />
      <LexicalComposer
        initialConfig={{
          editorState: initialState,
          namespace: "ShowcaseArticle",
          nodes: [HeadingNode, LinkNode, ListItemNode, ListNode, QuoteNode],
          onError: handleEditorError,
          theme: {
            heading: { h2: "lexical-h2", h3: "lexical-h3" },
            link: "lexical-link",
            list: { listitem: "lexical-list-item", nested: { listitem: "lexical-nested-list-item" }, ol: "lexical-ol", ul: "lexical-ul" },
            paragraph: "lexical-paragraph",
            quote: "lexical-quote",
            text: { bold: "lexical-bold", italic: "lexical-italic", underline: "lexical-underline" }
          }
        }}
      >
        <Toolbar />
        <div className="lexical-surface">
          <RichTextPlugin
            ErrorBoundary={LexicalErrorBoundary}
            contentEditable={<ContentEditable aria-label="Article body" aria-multiline="true" className="lexical-content-editable" />}
            placeholder={<div className="lexical-placeholder">Write the article body…</div>}
          />
          <HistoryPlugin />
          <LinkPlugin />
          <ListPlugin />
          <AutoFocusPlugin />
          <PersistencePlugin onDocumentChange={(nextState) => setEditorState(JSON.stringify(nextState.toJSON()))} />
        </div>
      </LexicalComposer>
    </section>
  )
}
