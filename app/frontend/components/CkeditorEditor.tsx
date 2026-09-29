// app/frontend/components/CkeditorEditor.tsx

import "ckeditor5/ckeditor5.css"

import {
  Autoformat,
  BlockQuote,
  Bold,
  ClassicEditor,
  CodeBlock,
  Essentials,
  Heading,
  Italic,
  Link,
  List,
  Paragraph,
  SelectAll,
  type Editor,
  type EditorConfig
} from "ckeditor5"
import { useEffect, useState } from "react"

export interface CkeditorEditorProps {
  textareaId: string
}

const initializedEditors = new WeakMap<HTMLTextAreaElement, Promise<Editor>>()

export const ckeditorConfiguration: EditorConfig = {
  licenseKey: "GPL",
  link: { addTargetToExternalLinks: true },
  plugins: [Autoformat, BlockQuote, Bold, CodeBlock, Essentials, Heading, Italic, Link, List, Paragraph, SelectAll],
  toolbar: {
    items: [
      "undo",
      "redo",
      "|",
      "heading",
      "|",
      "bold",
      "italic",
      "link",
      "|",
      "bulletedList",
      "numberedList",
      "blockQuote",
      "codeBlock"
    ],
    shouldNotGroupWhenFull: false
  }
}

function createEditor(textarea: HTMLTextAreaElement) {
  const existing = initializedEditors.get(textarea)
  if (existing) return existing

  const editor = ClassicEditor.create(textarea, ckeditorConfiguration)
  initializedEditors.set(textarea, editor)
  return editor
}

export default function CkeditorEditor({ textareaId }: CkeditorEditorProps) {
  const [failed, setFailed] = useState(false)
  const [status, setStatus] = useState("Loading rich editor…")

  useEffect(() => {
    const textarea = document.getElementById(textareaId)
    if (!(textarea instanceof HTMLTextAreaElement)) {
      setFailed(true)
      setStatus("Rich editor unavailable. Continue with the textarea fallback.")
      return
    }

    let disposed = false
    let editor: Editor | undefined
    const form = textarea.form
    const synchronize = () => {
      if (editor) textarea.value = editor.getData()
    }
    const destroy = () => {
      if (!editor) return

      initializedEditors.delete(textarea)
      const instance = editor
      editor = undefined
      void instance.destroy()
    }

    form?.addEventListener("submit", synchronize)
    document.addEventListener("turbo:before-cache", destroy, { once: true })

    void createEditor(textarea)
      .then((instance) => {
        if (disposed) {
          initializedEditors.delete(textarea)
          return instance.destroy()
        }

        editor = instance
        instance.model.document.on("change:data", synchronize)
        synchronize()
        setStatus("Rich editor ready")
      })
      .catch(() => {
        initializedEditors.delete(textarea)
        if (!disposed) {
          setFailed(true)
          setStatus("Rich editor unavailable. Continue with the textarea fallback.")
        }
      })

    return () => {
      disposed = true
      form?.removeEventListener("submit", synchronize)
      document.removeEventListener("turbo:before-cache", destroy)
      destroy()
    }
  }, [textareaId])

  return (
    <p
      aria-live="polite"
      className={failed ? "ckeditor-fallback-status" : "sr-only"}
      role={failed ? "alert" : "status"}
    >
      {status}
    </p>
  )
}
