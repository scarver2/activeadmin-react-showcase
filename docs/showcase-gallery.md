<!-- docs/showcase-gallery.md -->

# Visual Showcase Gallery

This gallery presents the merged visual features of the ActiveAdmin React
Showcase. Every image was captured from the seeded Rails application in real
Playwright Chromium at a 1440-pixel viewport. The accounts, people, messages,
files, and operations are deterministic synthetic fixtures; no production data
or machine-specific browser chrome appears here.

Screenshots document the finished interaction states. They supplement the
RSpec, Vitest, and Playwright coverage described in each feature guide; they do
not replace executable browser proof.

## ActiveAdmin V3 Theme

The installed `activeadmin-themes` V3 recipe gives native ActiveAdmin chrome,
the TanStack data island, and the surrounding Rails guidance a shared visual
foundation. See [ActiveAdmin Themes integration](themes.md).

![The V3-themed Account Data Explorer with native ActiveAdmin navigation and a populated React table](screenshots/activeadmin-v3-theme.png)

### Theme switcher comparison

The same deterministic account surface under both persisted semantic-token
palettes. Native ActiveAdmin chrome and the React island change together.

![The Account Data Explorer under the V3 Classic theme](screenshots/theme-v3-classic.png)

![The same Account Data Explorer under the Texas Bluebonnet theme](screenshots/theme-texas-bluebonnet.png)

## Analytics Dashboard

Thirty days of Rails-owned operating metrics rendered as focused React charts
and key performance indicators.

![Populated analytics dashboard with key metrics and trend charts](screenshots/analytics-dashboard.png)

## Lexical Editor

An ordinary ActiveAdmin article form enhanced with a rich-text React island
while preserving Rails validation and persistence.

![Lexical WYSIWYG editor containing a formatted synthetic Rodeo operations briefing](screenshots/lexical-editor.png)

The [Lexical WYSIWYG Editor](lexical-editor.md) keeps interactive formatting in
React while Rails validates canonical JSON and links, renders safe HTML, and
protects concurrent edits.

## TinyMCE Editor

A self-hosted TinyMCE build enhances an ordinary ActiveAdmin textarea while
Rails retains administrator scope, validation, sanitization, persistence, and
the media policy. See [TinyMCE WYSIWYG Editor](tinymce-editor.md).

![TinyMCE editor containing a deterministic synthetic operations briefing](screenshots/tinymce-editor.png)

The same server-sanitized document rendered by the ordinary ActiveAdmin show
page proves the persisted preview boundary.

![Server-rendered preview of the sanitized TinyMCE article](screenshots/tinymce-preview.png)

## Live Jobs / Operations Center

Solid Queue performs bounded work, SQLite persists lifecycle events, and Solid
Cable transports progress to the browser. See [Live Jobs / Operations
Center](live-jobs.md).

![Completed synthetic operation in the Live Jobs Operations Center](screenshots/live-jobs.png)

## Account Data Explorer

TanStack Table presents bounded, server-filtered account data without moving
query authority into the browser. See [Account Data Explorer](data-explorer.md).

![Account Data Explorer filtered to Cedar Ridge Health](screenshots/account-data-explorer.png)

## Operator Chat

Authenticated operators exchange persisted synthetic messages over Solid
Cable, with Rails retaining ownership of authorization and replay. See
[Operator Chat](operator-chat.md).

![Operator Chat showing a connected synthetic shift handoff](screenshots/operator-chat.png)

## File & Image Manager

Active Storage powers authenticated uploads, previews, downloads, and explicit
destructive confirmation. See [File & Image Manager](file-image-manager.md).

![File and Image Manager with an explicit delete confirmation](screenshots/file-image-manager.png)

## Kanban Workflow

Optimistic drag and drop is reconciled with Rails-authoritative workflow state
and ordering. See [Kanban Workflow](kanban-workflow.md).

![Kanban board after moving a synthetic work item into Review](screenshots/kanban-workflow.png)

## Agent Console

A provider-neutral deterministic agent streams persisted progress, a response,
and authorized citations without external credentials. See [Deterministic Agent
Console](agent-console.md).

![Completed deterministic agent run with synthetic account citations](screenshots/agent-console.png)

## Relationship Explorer

Rails performs bounded account and contact search while React provides a useful
master-detail view. See [Relationship and CRM Explorer](relationship-explorer.md).

![Relationship Explorer filtered to a synthetic integration engineer](screenshots/relationship-explorer.png)

## Command Palette

The keyboard-first palette searches authorized Rails-owned records with
deterministic ranking and navigation. See [Command Palette and Global
Search](command-palette.md).

![Open command palette showing a synthetic account result](screenshots/command-palette.png)

## Safe Terminal

xterm.js renders transcripts from an allowlisted command registry; no arbitrary
shell input reaches a process. See [Safe Terminal Console](safe-terminal.md).

![Safe Terminal showing a completed allowlisted showcase status command](screenshots/safe-terminal.png)

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
