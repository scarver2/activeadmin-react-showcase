// vite.config.ts

import { execFileSync } from "node:child_process"
import { resolve } from "node:path"

import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"

function activeAdminReactRoot() {
  if (process.env.ACTIVEADMIN_REACT_PATH) {
    return resolve(process.env.ACTIVEADMIN_REACT_PATH)
  }

  return execFileSync("bundle", ["show", "activeadmin-react"], { encoding: "utf8" })
    .trim()
    .split(/\r?\n/)
    .at(-1)!
}

export default defineConfig({
  plugins: [RubyPlugin(), react(), tailwindcss()],
  resolve: {
    dedupe: ["react", "react-dom"],
    alias: {
      "active_admin/react": resolve(activeAdminReactRoot(), "app/javascript/active_admin/react/index.js")
    }
  }
})
