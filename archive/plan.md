# Personal Assistant - Project Plan

## Vision

A CLI-first personal task management system powered by Claude. Voice-driven input, priority-aware task organization, and a visual dashboard — without the rigidity of Jira/Trello.

## Bootstrap Sequence

1. **Constitution** — establish project principles via `/speckit.constitution`
2. **Feature identification** — decompose this transcript into discrete, bounded features
3. **Iterative delivery** — specify, plan, implement, merge one feature at a time

## Features (Proposed Order)

| # | Feature | Why First/Next |
|---|---------|---------------|
| 1 | Core task management | Foundation everything else builds on — CRUD, priorities, sub-tasks, state, local storage |
| 2 | CLI interface | Primary interaction surface; enables manual use immediately |
| 3 | Voice command input | Bind to a hotkey, record, transcribe, interpret as task commands |
| 4 | Dashboard / reporting | Markdown -> HTML (with Mermaid); visual snapshot of current state |
| 5 | Source integrations | Pull tasks from GitHub PRs, calendar, meetings (GWS CLI), Claude Code hooks |
| 6 | System tray widget | Desktop presence (Linux/Wayland + Windows); surface dashboard |

## Open Questions

- **Streaming transcription PoC**: Can a persistent Claude session receive streamed prompts, or must each voice input launch a new session? Informs architecture of features 3+.
- **Feature boundaries**: How thin should feature 1 be before moving to feature 2? Minimum viable: add/list/complete/prioritize tasks via a data layer.
- **Storage format**: Flat files (Markdown/JSON) vs. SQLite? Flat files align with dashboard rendering; SQLite scales better.

## Workflow Per Feature

```
/speckit.specify  ->  /speckit.clarify  ->  /speckit.plan  ->  /speckit.tasks  ->  /speckit.implement
```

Each feature gets its own spec in `.specify/specs/`, its own branch, and merges to main when acceptable.

## Next Step

Run `/speckit.constitution` to establish project principles before any feature work.
