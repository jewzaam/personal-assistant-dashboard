# Personal Assistant - Detailed Planning Notes

## Source Material

This plan was derived from a voice transcript captured on 2026-03-25. The user described their vision for a personal task management system while testing the voice transcription skill.

## Problem Statement

The user manages tasks across many surfaces:
- Sticky notes on desk
- Calendar entries
- GitHub PRs (drafts, pending reviews)
- Ad-hoc requests from meetings (manager, team)

Priority management is the core pain point — things arrive at different urgency levels, priorities shift, and there's no single view of "what should I be doing right now?"

Existing tools (Jira, Trello) are too rigid. The user wants something flexible that an agent can help manage through natural language and voice.

## Dual Purpose

This project serves two goals:
1. **Build a useful tool** — a personal assistant that actually gets used daily
2. **Test speckit from ground zero** — exercise the full speckit workflow (constitution -> specify -> clarify -> plan -> tasks -> implement) on a clean repo, learning how to properly bound features and iterate

The user explicitly wants to be mindful of feature boundaries and gain experience with the speckit workflow.

## Feature Deep Dives

### Feature 1: Core Task Management

The data layer. Tasks have:
- Title, description
- Priority (needs a scheme — numeric? P0-P3? User-defined labels?)
- Status (at minimum: todo, in-progress, done)
- Sub-tasks (tree structure or flat with parent references?)
- Source (manual, github, calendar, voice)
- Timestamps (created, updated, due?)

Storage considerations:
- **Flat files (JSON/Markdown)**: Simple, git-friendly, easy to render as dashboard. Risk: concurrent writes, querying at scale.
- **SQLite**: Query-friendly, atomic writes, single file. Risk: not as directly renderable; needs export step for dashboard.
- Hybrid: SQLite for state, generate Markdown snapshots for dashboard rendering.

### Feature 2: CLI Interface

The user's primary interaction surface. Key commands:
- `pa add "task description" --priority high`
- `pa list [--filter status=todo] [--sort priority]`
- `pa done <task-id>`
- `pa priority <task-id> <new-priority>`
- `pa sub <parent-id> "sub-task description"`

Design considerations:
- Keep it simple — this is a personal tool, not a multi-user platform
- Output should be terminal-friendly but also parseable (JSON flag?)
- The CLI is also the interface that voice commands will target

### Feature 3: Voice Command Input

Two modes to investigate:

**Mode A — Fire-and-forget (simpler, implement first)**:
- Keybinding triggers: record -> transcribe -> parse as CLI command -> execute
- Each invocation is independent
- Uses existing voice transcription infrastructure

**Mode B — Persistent session (PoC needed)**:
- A long-running Claude session acts as the "assistant"
- Voice input streams into it as prompts
- More conversational: "move that thing I was working on yesterday to high priority"
- Requires solving: how to feed transcribed text into a running Claude Code session

The user acknowledged Mode B is aspirational and Mode A is sufficient for initial delivery.

### Feature 4: Dashboard / Reporting

- Render current task state as Markdown
- Convert to HTML (user has existing tooling for this)
- Support Mermaid diagrams (dependency graphs, priority distributions, burndown?)
- Could be a static page regenerated on task changes, or served locally

### Feature 5: Source Integrations

Pull tasks from external systems:
- **GitHub**: Draft PRs authored by user, PRs pending review, assigned issues
- **Google Calendar / Meet (via GWS CLI)**: Discover meetings (attended or missed), pull transcripts and recordings, extract action items from Gemini notes. GWS CLI is already authenticated with calendar, docs, drive, meet scopes. Usage notes at `~/gws-notes.md`.
- **Meeting transcripts**: Meeting CC or transcript discovery fed into the assistant. Transcript-to-task extraction is a slow WIP but eventually hooks in here.
- **Claude Code hooks**: Inspect all Claude activities happening across sessions — a source of "what am I working on" context. Doesn't cover meetings but covers all dev activity.
- These become tasks with `source: github`, `source: calendar`, `source: meeting`, `source: claude-activity`
- Sync strategy: one-way import? Periodic refresh? On-demand?

### Feature 6: System Tray Widget

- Desktop presence using system tray (Linux/Wayland, Windows)
- User has written TkInter standards and has existing projects as reference
- Could show: task count badge, quick-add, priority alerts
- User did cited-research on cross-platform pitfalls — reference that

### Cross-Cutting: Proactive Feedback

The assistant should not just display state — it should actively nudge the user. Two modes:

**Real-time feedback:**
- Detect when the user is working on something that isn't their top priority
- Requires awareness of current activity (Claude Code hooks) and the priority stack
- Lightweight interrupts, not blocking — a notification or terminal message

**Retrospective insights (dashboard):**
- Analyze meetings attended and assess whether attendance was necessary
- Signals: did the user speak? Were action items assigned to them? Could the content have been consumed async via transcript?
- Not a rigid RACI check — more like pattern detection that improves over time based on user feedback
- Could surface: "You attended 3 meetings this week where transcript review would have sufficed"
- Requires meeting transcript analysis + participation data from GWS/Meet APIs

The retrospective side is judgment-heavy. The agent would need to learn what "necessary attendance" looks like for this specific user over time — initial heuristics refined by explicit feedback ("no, that one was important because...").

## Streaming Transcription PoC

Not necessarily part of the initial feature set, but important to investigate:
- Can Claude Code accept piped input from a running transcription?
- Or does the architecture require fire-up-per-prompt?
- This PoC informs other projects the user has in mind
- Could be explored as a spike between features 2 and 3

### Cross-Cutting: Git Checkpoint Action

The assistant should have a "commit changes" action (CLI command or dashboard button) that stages modified artifacts and commits them. This provides rollback insurance — if the model goes sideways and deletes or mangles planning docs, the user can revert to the last checkpoint. This applies to planning docs, specs, dashboards, and any other durable artifacts the assistant manages.

## Architecture Thoughts

- **Language**: Not yet decided. Python is likely given the existing voice tooling and TkInter standards. Could also be a mix (Go CLI + Python for voice/GUI).
- **Modularity**: Each feature should be independently testable. The core task management is a library; CLI is a consumer; voice/dashboard/tray are additional consumers.
- **Configuration**: XDG-compliant config directory (`~/.config/personal-assistant/` or similar)

## Speckit Learning Goals

The user wants to learn through this project:
- How to identify feature boundaries from a brain dump
- How to scope specs so they're implementable in one branch
- How to iterate on a shipped feature without derailing current work
- Whether dumping a transcript like this is a viable way to seed feature specs
- The discipline of constitution -> specify -> clarify -> plan -> tasks -> implement
