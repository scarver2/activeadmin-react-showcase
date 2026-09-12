<!-- docs/hierarchy-explorer.md -->

# Hierarchy Explorer

The Hierarchy Explorer demonstrates recursive administrative data without moving hierarchy policy into the browser. Open **Data & Workflows → Hierarchy Explorer** to expand the deterministic organization, select nodes, inspect breadcrumbs, and reparent through pointer drag or keyboard-accessible controls.

## Demo

Children load only when a branch opens. Moves appear optimistically, but Rails validates ownership, cycle prevention, a four-level depth limit, ordering, and the submitted lock version. Rejected proposals restore the prior tree. A nested ActiveAdmin list and ordinary edit forms remain available without JavaScript.

## Ruby

`Hierarchy::Query` scopes direct-child reads to the authenticated administrator and caps each response at 50 nodes. `Hierarchy::Reparent` resolves parents through the same owner scope, locks the moved record, and persists only model-valid adjacency-list relationships.

## JavaScript

`HierarchyExplorer` owns expansion, selection, loading indicators, breadcrumbs, and drag/keyboard presentation. It consumes Rails-generated URLs and treats every move as reversible until the server returns a canonical node.

## Architecture

The SQLite schema uses a portable self-referencing foreign key and explicit sibling positions. Recursive meanings remain application-owned; no generic tree abstraction or database-specific recursive query has been introduced.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
