# Personal Assistant — Requirements Brain Dump

> **Status**: Raw capture from voice transcription. Not yet prioritized or validated.

---

## TL;DR

A context-aware personal assistant that monitors calendars, Jira, and GitHub to surface what matters, flag conflicts, and maintain situational awareness — operating primarily as a **state receiver/monitor** rather than an active collector, with a local git repo as the state store.

---

## 1. Calendar Intelligence

### 1.1 Multi-Calendar Awareness
- Monitor personal calendar **and** shared org/engineering calendars
- Identify events on shared calendars that are relevant to tracked work

### 1.2 Relevance Matching
Events should be correlated to tracked features/work via:
- **Label/tag matching** (e.g. Jira labels)
- **Text matching** — event title/description references a domain keyword (e.g. "authorization") or epic ID (e.g. "1900")
- **Hierarchy traversal** — a tracked epic's child epics/stories/tasks may have associated calendar events; roll those up to the parent feature

### 1.3 Meeting Recommendations
When a relevant meeting is found that I'm not attending:
- Present: "Should I add you to this meeting?" or "This is something you should add yourself to"
- Mechanics of calendar modification TBD

### 1.4 Conflict Management
When added to meetings that create conflicts:
1. **Identify** all conflicts
2. **For each conflict**, determine:
   - Can I request a move? (don't own it)
   - Can I move it myself? (own it — but may still need coordination)
   - Should I decline due to higher-priority meeting?
3. Present options; do not act autonomously

### 1.5 Transcription Monitoring

**Rule: Transcription should be ON by default except for true 1-on-1s**

Define 1-on-1: meeting where there is exactly **one other attendee/invitee** besides myself **AND** the title contains "1:1", "1 on 1", or it is a recurring sync with a single individual.

- If I **own** the meeting and transcription is off → recommend enabling it by default
- If I **don't own** the meeting and transcription should be on → flag it; notify me at meeting start so I can manually enable it
- Notification/reminder system needed for meeting-start alerts

**Caveat**: 1-on-1 meetings that are topic-specific (not just a standing sync) should also have transcription on.

---

## 2. Meeting Context & Catchup

### 2.1 Context Sources (in priority order)
- Written meeting notes attached to the event
- Gemini-generated notes/summaries
- Gemini transcripts
- Google Meet recordings

### 2.2 Known Gap
Not all attendees enable recording/transcription. The PA should help close this gap (see §1.5) but cannot guarantee coverage.

---

## 3. Jira Tracking

### 3.1 Two Tiers of Tracking

| Tier | Mode | Use Case |
|------|------|----------|
| **Awareness** | High-level summary only | General visibility; drill-down on demand |
| **Active** | Full depth | Architect/owner; need to catch blockers, direction changes |

- Summarization logic should be **identical** between tiers; only **depth of presentation** differs

### 3.2 Proactive Alerts
Bring something to my attention when:
- A change in direction occurs on a tracked item (definition of "direction change" TBD)
- I am explicitly tagged as needing to provide input or context

### 3.3 Reporting Modes
- On-demand summary
- Daily digest (cadence TBD)
- Proactive push for high-signal events (tags, direction changes)

### 3.4 Scope
- Track features (epics) and their full child hierarchy: epics → stories → tasks
- MCP server: **Atlassian/Jira** (enabled)

---

## 4. GitHub Tracking

### 4.1 Spec-Driven Development Context
- Org is moving toward spec-driven development (may not apply to all repos going forward)
- Need awareness of spec changes

### 4.2 What to Monitor
- Open pull requests against specific repositories (list TBD)
- State changes on those PRs
- Analysis of committed changes: code, docs, specs
- PR comments provide context; **committed source is authoritative**

### 4.3 Analysis Inputs
- Actual diff (committed changes)
- Commit messages (context, not authority)
- PR comments (context only)

---

## 5. Architecture & Data Model

### 5.1 PA Role: State Monitor, Not Collector
- PA is a **receiver** — it reads from state on disk
- A **separate workflow layer** is responsible for pulling data:
  - Meeting data (calendar + transcripts)
  - GitHub state
  - Jira state
- PA monitors for state changes and acts on them

### 5.2 Local Git Repo as State Store
- All meeting transcripts, notes, GitHub state snapshots stored in a local git repo
- State is snapshotted via commits (git add + git commit = "reviewed checkpoint")
- PA workflow:
  1. Inspect what has changed since last commit
  2. Run analysis on the delta
  3. Commit current state (encoding this into tooling required)

### 5.3 Agentic Execution Constraints

⚠️ **Critical constraint: No autonomous agentic approval of permission requests**

- Agent cannot auto-approve permission prompts
- SDK integration or a wrapper around a running Claude instance are candidate approaches
- Need to figure out how human-in-the-loop approval works for agentic actions
- This is an **open architectural problem** — needs a dedicated design session

---

## 6. Open Questions

| # | Question | Priority |
|---|----------|----------|
| 1 | How is the "tracked features" list managed? Jira labels, manual list, both? | High |
| 2 | What defines a "direction change" on a Jira item? | High |
| 3 | Mechanics of calendar modification — who/what can write to calendar? | High |
| 4 | How does the PA notify/alert? Push notification, dashboard, chat? | High |
| 5 | Which GitHub repos are in scope? | Medium |
| 6 | Agentic approval workflow — how to handle without auto-approving permissions? | High |
| 7 | Daily digest format and delivery mechanism | Medium |
| 8 | How do we handle Gemini transcript availability (not guaranteed)? | Medium |

---

## 7. Integrations Required

| Integration | Status | Notes |
|-------------|--------|-------|
| Google Calendar (personal) | TBD | Read + write (for move/decline) |
| Google Calendar (shared/engineering) | TBD | Read only |
| Google Meet | TBD | Transcription state detection |
| Jira / Atlassian | MCP enabled | Read; proactive alerts |
| GitHub | TBD | PR + diff monitoring |
| Gemini | TBD | Notes/transcript retrieval |
| Local git repo | TBD | State store; diff since last commit |

---

*Captured from voice transcription — March 2026*
