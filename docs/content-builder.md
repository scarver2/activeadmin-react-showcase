<!-- docs/content-builder.md -->

# Content Builder

## Demo

Add, remove, select, edit, drag, or keyboard-reorder heading, paragraph, and callout blocks. The live preview is explicitly provisional until Save succeeds. A server-rendered list and ordinary ActiveAdmin records remain available without JavaScript.

## Ruby

`ContentBuilder::Save` replaces normalized `ContentBlock` rows transactionally. Rails enforces ownership, exactly allowlisted attributes and block types, contiguous ordering, a twelve-block cap, validation, and optimistic locking.

## JavaScript

React owns transient composition and preview state. dnd-kit supplies bounded drag semantics; named move buttons preserve keyboard access. A rejected save restores the last canonical Rails projection.

## Architecture

The schema is deliberately small and application-owned. It stores no arbitrary HTML or executable browser document and does not claim to be a generic page-building framework.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
