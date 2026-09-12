<!-- docs/spacecraft-viewer.md -->

# Three.js Spacecraft Viewer

## Demo

Orbit, pan, and zoom the local Odyssey engineering demonstrator; use named camera presets, inspect three selectable components, toggle the exploded view, and persist an allowlisted finish. The component list is the keyboard alternative and the Rails fallback preserves all engineering metadata.

## Ruby

Rails owns the model identity, local asset URL, component IDs and metadata, authorization, finish allowlist, selected component, optimistic locking, and generated configuration endpoint. Unsupported IDs or finishes are rejected.

## JavaScript

The Three.js chunk and tiny embedded-buffer glTF load only on this page. Rendering caps device pixel ratio at two, uses no remote textures or HDRI, respects reduced-motion preferences, reports model/WebGL failure, and disposes controls, animation frames, listeners, renderer, geometry, and materials on unmount.

## Architecture

The committed model has three named low-polygon parts, one material, no textures, and one draw-call-friendly mesh definition. This is a lifecycle and authority demonstration—not CAD, a game engine, or a generic scene editor—and creates no speculative `activeadmin-react` API.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
