# Personal Assistant — MVP Plan

## Goal

A GUI window that acts as the single interaction surface for a Claude-powered personal assistant. Text or voice in, Claude handles it. Get something working today, iterate from there.

## Architecture Decision

- **GUI**: Python + TkInter (user has standards, cross-platform Linux/Windows)
- **Claude integration**: `claude -p "prompt"` for one-shot commands, `--continue` to maintain conversation context within a session
- **Voice**: Reuse existing voice transcription infrastructure (faster-whisper)
- **Storage**: Obsidian vault for notes/meeting artifacts; flat files for task state (revisit if needed)
- **Config**: `~/.config/personal-assistant/`

## Phase 0 — GUI Shell (today)

Build a minimal TkInter window:
- Text entry field + Send button
- Voice record button (reuses voice skill's recording/transcription)
- Output area showing Claude's response
- Sends input to Claude via `claude -p`, displays response
- No persistence, no integrations, no task management — just the interaction loop

**PoC validated**: `claude -p "prompt"` works for injection. `claude -p --continue` resumes conversations. The `@anthropic-ai/claude-code` SDK exists for deeper programmatic control if needed later.

**Done when**: User can type or speak something, see Claude's response in the window.

## Phase 1 — Calendar Awareness

- Pull meeting list from Google Calendar via GWS CLI
- For each meeting: check for transcript, Gemini notes, meeting note doc
- Surface documents the user doesn't have access to as "request access" tasks
- Periodically re-check access (up to 14 days) after request is made
- Store discovered artifacts as references (links to upstream + local copies)

**Depends on**: GWS CLI (already authenticated — calendar, docs, drive, meet scopes). Usage notes at `~/gws-notes.md`.

## Phase 2 — Notes System (Obsidian)

- Establish Obsidian vault structure for meeting notes, 1:1s, general notes
- Tag-based organization (by person, by meeting series, by topic)
- "Open notes for 1:1 with [person]" command from the PA window
- Meeting notes in Markdown, linked to transcripts/recordings
- Links: raw upstream URL (Google) + local Markdown copy
- Screenshots from meetings: copy to vault, attach to meeting note

**Key decision**: Obsidian is the durable store. The PA is the input/discovery layer — it finds and collects artifacts, Obsidian organizes them.

## Phase 3 — JIRA + GitHub

### JIRA
- Summary view of ANSTRAT-level items the user cares about (dynamically configured)
- Surface status changes, blockers, new assignments

### GitHub
- PRs authored by user (non-personal repos) — status, review state
- PRs where user is requested reviewer — pending action
- **Stale re-review detection**: PRs where user requested changes, author later commented/pushed, but did not re-request review

## Phase 4 — Task Management + Research

- Ad-hoc tasks: add, prioritize, complete from the PA window
- Priority scheme (TBD — start simple, P0-P3 or numeric)
- Due dates optional
- Dispatch cited-research skill autonomously ("go research X")
- Standardized location for research outputs
- Integration: tasks from all sources (manual, calendar, JIRA, GitHub) in one view

## Cross-Cutting Concerns

### Proactive Feedback
- Detect misalignment between current activity and top priorities (requires Claude Code hooks for activity awareness)
- Retrospective meeting analysis: was attendance necessary? Could transcript have sufficed?
- Pattern detection improves over time with user feedback

### Git Checkpoints
- Commit durable artifacts frequently — planning docs, specs, vault structure
- Rollback insurance against model drift

## Non-Goals (for now)
- System tray widget (Phase 0 GUI is sufficient initially)
- Persistent Claude session (fire-and-forget via `claude -p` is fine for MVP)
- Multi-user anything
- Speckit ceremony (may revisit per-feature once momentum is established)
