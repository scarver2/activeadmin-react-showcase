// tailwind-active_admin.config.js

import { execSync } from "node:child_process"

import activeAdminPlugin from "@activeadmin/activeadmin/plugin"

// Always use the last line of output since Bundler's DEBUG env will print additional lines.
const activeAdminPath = execSync("bundle show activeadmin", { encoding: "utf8" }).trim().split(/\r?\n/).pop()

export default {
  content: [
    `${activeAdminPath}/vendor/javascript/flowbite.js`,
    `${activeAdminPath}/plugin.js`,
    `${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}`,
    "./app/admin/**/*.{arb,erb,html,rb}",
    "./app/frontend/**/*.{js,jsx,ts,tsx}",
    "./app/views/active_admin/**/*.{arb,erb,html,rb}",
    "./app/views/admin/**/*.{arb,erb,html,rb}",
    "./app/views/layouts/active_admin*.{erb,html}"
  ],
  darkMode: "selector",
  plugins: [activeAdminPlugin]
}
