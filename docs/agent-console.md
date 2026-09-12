<!-- docs/agent-console.md -->

# Deterministic Agent Console

The agent console demonstrates progressive agent UX without an LLM account or
credential. Every response is deterministic and operates only on synthetic
showcase concepts.

`AgentRun` records an authorized prompt and lifecycle. Its ordered `AgentEvent`
history contains activity, progressive response fragments, citations, and the
terminal result. These are the only durable nouns: providers, tools, prompt
templates, and citations are bounded application vocabulary or event payloads,
not speculative tables.

Solid Queue performs the work outside Cable. Solid Cable authorizes each stream
to the owning administrator and replays events after the browser's last durable
sequence. React renders the timeline, response, citations, cancellation, and a
reconnect demonstration; it never determines lifecycle meaning.

The ordinary Rails form remains usable without JavaScript and recent persisted
runs remain readable in the fallback. No reset is exposed because run history is
meaningful application state.

Run the complete local contract with:

```bash
bin/test
bin/browser-test
```

See [`activeadmin-react`](https://github.com/scarver2/activeadmin-react) for the
generic island lifecycle; the agent models and UI intentionally remain in this
application.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
