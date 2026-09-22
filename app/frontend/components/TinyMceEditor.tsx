// app/frontend/components/TinyMceEditor.tsx

import "tinymce/skins/ui/oxide/skin.css"

import { useEffect, useState } from "react"
import tinymce from "tinymce"
import type { Editor } from "tinymce"

export interface TinyMceEditorProps {
  textareaId: string
}

function contentStyle() {
  const styles = window.getComputedStyle(document.body)
  const background = styles.backgroundColor
  const foreground = styles.color

  return `
    body { background: ${background}; color: ${foreground}; font-family: ui-sans-serif, system-ui, sans-serif; margin: 1rem; }
    a { color: #2563eb; }
    blockquote { border-inline-start: 0.25rem solid #94a3b8; margin-inline: 0; padding-inline-start: 1rem; }
    code, pre { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
  `
}

async function loadTinyMceExtensions() {
  await Promise.all([
    import("tinymce/icons/default"),
    import("tinymce/models/dom"),
    import("tinymce/plugins/autolink"),
    import("tinymce/plugins/code"),
    import("tinymce/plugins/link"),
    import("tinymce/plugins/lists"),
    import("tinymce/plugins/wordcount"),
    import("tinymce/themes/silver")
  ])
}

export default function TinyMceEditor({ textareaId }: TinyMceEditorProps) {
  const [status, setStatus] = useState("Loading rich editor…")
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    const textarea = document.getElementById(textareaId)
    if (!(textarea instanceof HTMLTextAreaElement)) {
      setFailed(true)
      setStatus("Rich editor unavailable. Continue with the plain-textarea fallback.")
      return
    }

    let editor: Editor | undefined
    let disposed = false
    const form = textarea.form
    const save = () => editor?.save()

    form?.addEventListener("submit", save)
    const initialize = async () => {
      try {
        await loadTinyMceExtensions()
        if (disposed) return

        const editors = await tinymce.init({
          automatic_uploads: false,
          branding: false,
          content_css: false,
          content_style: contentStyle(),
          license_key: "gpl",
          menubar: false,
          paste_data_images: false,
          plugins: "autolink code link lists wordcount",
          promotion: false,
          setup(instance) {
            editor = instance
            instance.on("init", () => {
              if (!disposed) setStatus("Rich editor ready")
            })
          },
          skin: false,
          target: textarea,
          toolbar: "blocks | bold italic | bullist numlist blockquote | link | code",
          valid_elements: "p,h2,h3,strong/b,em/i,ul,ol,li,blockquote,pre,code,a[href|title],br",
          valid_styles: {},
          height: 460
        })
        if (disposed) editors.forEach((initializedEditor) => initializedEditor.remove())
      } catch {
        if (!disposed) {
          setFailed(true)
          setStatus("Rich editor unavailable. Continue with the plain-textarea fallback.")
        }
      }
    }

    void initialize()

    return () => {
      disposed = true
      form?.removeEventListener("submit", save)
      editor?.remove()
    }
  }, [textareaId])

  return <p aria-live="polite" className={failed ? "text-red-700" : "sr-only"} role={failed ? "alert" : "status"}>{status}</p>
}
