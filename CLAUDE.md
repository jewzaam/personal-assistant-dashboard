# personal-assistant-dashboard

Tkinter GUI dashboard for personal task management and situational awareness. Integrates Google Calendar, Claude (Agent SDK + CLI), voice transcription, and a git-backed state store.

**Package:** `personal_assistant_dashboard`
**CLI entry point:** `pa` (e.g., `pa gui`, `pa collect calendar`, `pa analyze calendar`)
**Version:** see `personal_assistant_dashboard/__init__.py`

## Build & Test

```bash
make install-dev   # editable install with dev deps into .venv
make check         # test-format + test-lint + test-typecheck + test-unit + test-coverage (default target)
make run           # launch GUI (reads pa_workspace from config)
```

Individual targets: `make format`, `make test-lint`, `make test-typecheck`, `make test-unit`, `make test-coverage`, `make mutation`.

Coverage target: 80% on non-UI code. UI modules (`dashboard.py`, `*_tab.py`, `config.py`) are excluded — Tkinter testing is impractical.

## Architecture

**Data flow:** Collectors → State Repo (git) → Analyzers → UI

- **`collectors/calendar_collector.py`** — fetches Google Calendar events via GWS CLI (`gws calendar events list --page-all`)
- **`analyzers/calendar_analyzer.py`** — diffs current vs `HEAD` to detect new/cancelled/moved/attendee-changed events and conflicts
- **`analyzers/actions_analyzer.py`** — detects all-attendees-declined alerts
- **`state_repo.py`** — git-backed state store at `~/.local/share/claude-personal-assistant`
- **`config_manager.py`** — manages `config/tracking.yaml` (Jira epics, GitHub repos, calendars)
- **`models.py`** — TypedDicts (`CalendarEvent`, `Attendee`, etc.). `Attendee` includes `display_name` field captured from Google Calendar API `displayName`
- **`utils.py`** — `run_cmd()` subprocess wrapper, `atomic_write_json()`, `atomic_write_text()`, `get_gdoc_tab_url(doc_id, tab_name)` (resolves Google Docs tab name to direct URL via gws CLI with session-level caching), `resolve_display_name(email)` (resolves email to display name via People directory API with session-level caching)
- **`checkpoint.py`** — git add/commit/push on background thread
- **`tasks_md.py`** — parser and write-back for `<pa_workspace>/actions.md`, the PA's markdown task list. Headings are sections, bullets are tasks, deeper-indented bullets are detail lines on the task above. A bullet with no checkbox at all is an open task, so the PA needs no format change. `Task.key` is the bullet text **only** — the PA reshuffles actions.md by due date, and a task moving from a date section to `(TODAY)` to `Overdue` must not read as new. `set_done()` and `move_task()` re-read the file and refuse the write when the target line no longer matches the task, so a concurrent PA edit is never clobbered. `bump_target()` is the arrow rule: today is the floor in both directions, so a named bucket ("Overdue", "Demos to watch") only moves down and lands on today, and steps skip weekends. `move_task()` carries the task's detail lines with it, creates a missing date section in date order above the named buckets, and drops a dated section it empties — named buckets stay, they are structure the user maintains
- **`tasks.py`** — a Google Task with a due date **and time** comes back from Calendar API `events.list` as an ordinary event: `event_type: "focusTime"`, no attendees, and a `https://tasks.google.com/task/<id>` link in the description. That link is the only reliable marker (`is_task_event()`) — `event_type` alone also matches real Focus Time blocks. Date-only tasks never reach the calendar. **Do not try to clear due dates via the Tasks API** — verified 2026-08-18 against live data: `tasks.tasks.list` returns `due` truncated to a date (`T00:00:00.000Z`) for every task, so timed and date-only tasks are indistinguishable there and a write would strip due dates from tasks that were never on the calendar. `@default` is also the only task list for this account, so it is no narrowing. The calendar tab drops task-backed events from `events.json` unconditionally — no toggle, no scope. Completion state is irrelevant under that rule, which is why nothing tries to detect it

### UI modules (not unit tested)

- **`dashboard.py`** — main Tkinter window, tab management, window geometry
- **`chat_tab.py`** — Chat tab with Claude Agent SDK streaming
- **`chat_client.py`** — `ClaudeSDKClient` wrapper in background asyncio thread
- **`prs_tab.py`** — PRs tab showing open PRs where review is requested and PRs authored by user. Data from GitHub Search API via `gh api`. Has dismiss/restore, sort toggle, draft filter, dismissed filter. Auto-refreshes every 5 min (silent — no "Refreshing..." text; manual ↻ click still shows it). Refresh guard (`_refreshing` flag) prevents overlapping threads; skip counter escalates from `warning` (1–6 skips) to `error` (7+) in Console. Detects new review requests via URL set diff between refreshes — triggers tab bell + per-PR `warning` in Console with clickable link. ↻ button turns `COLOR_PROGRESS` while refresh is in flight. Row order is age, star, dismiss, change-request count, comments, diffstat, `[scode]`, then the PR link. `[scode]` launches `scode --profile <personal|work> <pr url>` via `subprocess.Popen` — fire-and-forget, because it opens an editor and `run_cmd()` would block the UI thread waiting on it. It takes the row's link color (dim reads as inert). **`--profile` is required when scode would create a new sandbox**: public repos get `personal`, private get `work`. Visibility comes from `isPrivate` on the repo node of the GraphQL query `_fetch_pr_details()` already issues, so it costs no extra call and the click needs no network. A repo missing from `repo_private` is treated as private — putting private code in a personal-profile sandbox is the failure that matters, an unnecessary `work` profile is not — and the fallback warns in Console. A missing `scode` reports to Console: the dashboard starts from an XDG autostart `.desktop`, which does not inherit a login shell's PATH, so a binary that works in a terminal can still be absent here
- **`tasks_tab.py`** — Tasks tab rendering `actions.md`. Row controls are `× ▲ ▼`: mark done, bump one business day earlier, bump one later. `Done:N` filter shows completed tasks, `+` restores. Headings collapse on click, remembered in `collapsed_sections.json`. Markdown links and bare URLs render clickable. **Row controls are tagged text, not embedded `tk.Button`s** — a button is 24px tall on a 20px line, so a row of them dwarfs the task text, and a long actions.md would carry one widget per control. Polls the file's mtime every `TASKS_POLL_INTERVAL_MS` (5 min) — no thread, the read is local and small; also re-renders when the date rolls over, because arrow targets are computed at render and this dashboard runs overnight. `action:` quick-capture calls `refresh(alert=False)` directly so a task typed into the dashboard does not wait out the poll. New open tasks trigger tab bell + per-task `warning` in Console, matching the PRs tab; the seen-key set persists to `seen_tasks.json` so a restart doesn't re-alert
- **`settings_tab.py`** — settings editor with git checkpoint
- **`config.py`** — constants (colors, fonts, timeouts)

### Other modules

- **`claude_client.py`** — wraps `claude -p` subprocess for one-shot prompts
- **`voice_input.py`** — mic recording via `local-transcribe`
- **`usage_poller.py`** — Anthropic 5-hour quota polling with caching/backoff
- **`gws_auth.py`** — GWS CLI OAuth scope checking
- **`startup.py`** — XDG autostart `.desktop` file management

## Configuration

Dashboard reads workspace path from `~/.claude/personal-assistant-config.json`:

```json
{
  "pa_workspace": "~/source/personal-assistant-work",
  "ONE_ON_ONE_DOC_ID": "doc-id-here"
}
```

- **`pa_workspace`** — dashboard working directory
- **`ONE_ON_ONE_DOC_ID`** — Google Doc ID for 1:1 meeting notes. Used to link 1:1 meetings to Google Docs tabs. Loaded in `config.py`

The dashboard runs from the `pa_workspace` directory, not from this repo. `PYTHONPATH` is set to this repo's root at launch (see `make/run.mk`).

Tracking config lives in the state repo: `<state_repo>/config/tracking.yaml`.

## Integrations

- **Google Calendar** — via GWS CLI binary (`gws`). Auth: `~/.claude/.credentials.json`
- **Claude Agent SDK** — `claude-agent-sdk>=0.1.50` for Chat tab
- **Claude CLI** — `claude -p` subprocess for one-shot prompts
- **Voice** — `local-transcribe` library (faster-whisper, CUDA optional via `[cuda]` extras)
- **Anthropic usage API** — OAuth token from `~/.claude/.credentials.json`

## Project history

Evolved from two predecessor repos:
1. **`claude-dashboard`** — session-monitoring dashboard (still separate)
2. **`claude-personal-assistant`** — combined personal assistant (this repo was extracted from it on 2026-04-04)

The rename dropped meeting transcript pipeline dependencies and made the workspace path configurable.

## Platform notes

- **Wayland/Mutter geometry:** `geometry()` returns stale position after user drags (XWayland doesn't send `ConfigureNotify`). `winfo_rootx()`/`winfo_rooty()` stay accurate. All position reads go through `_winfo_frame_geometry()` which converts `winfo_rootx/y` to WM-frame coordinates via a one-time offset (`_frame_dx`/`_frame_dy`). See [docs/wayland-geometry.md](docs/wayland-geometry.md) for full details.
- **Window decorations:** Motif hints via `xprop` remove decorations while keeping keyboard focus. Fallback: `overrideredirect(True)`. Neither `-type dock` (breaks focus) nor `-type splash` (breaks clipboard) is used.
- **Click handling:** Single-click defers 200ms, double-click cancels it (Linux Tkinter fires `<ButtonRelease-1>` before `<Double-1>`).
- **Canvas focus:** Calendar canvas uses `takefocus=True` with explicit click-to-focus binding.
- **BMP-only Unicode for buttons:** Tkinter on Linux cannot render supplementary plane Unicode (U+10000+). All button/label text must use BMP characters (U+0000–U+FFFF). Examples: `↻` (U+21BB) not `🔄` (U+1F504), `♪` (U+266A) not `🎤` (U+1F3A4).
- **Notebook scroll disabled:** `ttk.Notebook` has built-in scroll-to-change-tab behavior. Disabled via `bind("<Button-4/5/MouseWheel>", lambda e: "break")` on the notebook widget to prevent accidental tab switching.
- **Tab notification matching uses `startswith()`:** `_show_bell()`/`_hide_bell()` match tabs via `startswith()` on tab text. Pass the base name prefix to `_notify_tab()` (e.g., `"PR"` not `"PRs"`) because tab text is dynamic (`"PR:5"`). Wrong prefix = bell silently fails. `_on_tab_changed()` derives the prefix back out with `tab_text.split(":", 1)[0]`, so a count-suffixed tab needs no branch there — but a tab whose dynamic text is not `Name:count` (Calendar's `"Calendar ⏱2m"`) does.
- **Thread-safe tkinter from background threads:** Never call `widget.configure()` directly from a background thread. Use `self._schedule(widget.configure, {"fg": color})` — dict-arg form works with `_schedule` which calls `root.after(0, fn, *args)`.
- **1:1 notes link:** Calendar detail panel shows a "Notes" section for 1:1 meetings with a link to the Google Docs tab for the other attendee. Uses People directory API to resolve attendee email to display name, then matches against doc tabs. Cache warmed during calendar refresh background thread.

## Console log integration for tabs

Tabs that need to write to the Console tab receive a `console_log` callback in their constructor (same signature as `Dashboard.log_console`: `message, tag, link, link_label`). Use a `_log()` helper method that routes to `console_log` if available, falls back to `logger.warning()`. The helper passes through `link`/`link_label` for clickable console links. Tags: `"info"`, `"warning"`, `"error"` (error triggers tab bell on Console), `"success"`, `"progress"`.

## Tab toolbar standard

Tabs with a refresh action follow a consistent layout: `↻` button is the **leftmost element** in the top toolbar frame, using `COLOR_BUTTON`/`FG_TEXT`, `relief=tk.FLAT`, `padx=4`, packed `side=tk.LEFT, padx=(PAD, 4)`. Tab-specific controls (nav, filters, toggles) follow to the right. Status labels pack to the right side.

## Keyboard shortcuts

Two shortcut patterns:

- **Always-on shortcuts** (j/k/t for calendar nav): bound via `_window.bind("<Key-X>", handler)`. Handlers guard with `_is_text_focused()` (returns True if a Text/Entry/Combobox has focus) AND check the active tab is the calendar tab via `_cal_tab_id`. Adding new always-on shortcuts must follow this same pattern.
- **Transient menu shortcuts** (a/m/d/c for right-click context menu actions): bound via `_bind_menu_key()` which uses `_root.bind_all()` and records the sequence in `_menu_key_bindings`. All bindings are removed in `_dismiss_context_menu()`. These also guard `_is_text_focused()` inside `_bind_menu_key`. Menu shortcuts only exist while the context menu is visible.

**Critical:** All keyboard shortcuts must guard `_is_text_focused()` — `bind_all` fires even when text input widgets have focus. The guard is general-purpose (checks widget type), not per-shortcut.

## Autostart

`~/.config/autostart/pa-dashboard.desktop` launches the dashboard on GNOME login. Points to this repo's venv and module.
