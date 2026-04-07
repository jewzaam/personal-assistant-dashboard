# personal-assistant-dashboard

Tkinter GUI dashboard for personal task management and situational awareness. Integrates Google Calendar, Claude (Agent SDK + CLI), voice transcription, and a git-backed state store.

**Package:** `personal_assistant_dashboard`
**CLI entry point:** `pa` (e.g., `pa gui`, `pa collect calendar`, `pa analyze calendar`)
**Version:** see `personal_assistant_dashboard/__init__.py`

## Build & Test

```bash
make install-dev   # editable install with dev deps into .venv
make check         # format + lint + typecheck + test + coverage (default target)
make run           # launch GUI (reads pa_workspace from config)
```

Individual targets: `make format`, `make lint`, `make typecheck`, `make test`, `make coverage`, `make mutation`.

Coverage target: 80% on non-UI code. UI modules (`dashboard.py`, `*_tab.py`, `config.py`) are excluded — Tkinter testing is impractical.

## Architecture

**Data flow:** Collectors → State Repo (git) → Analyzers → UI

- **`collectors/calendar_collector.py`** — fetches Google Calendar events via GWS CLI (`gws calendar events list --page-all`)
- **`analyzers/calendar_analyzer.py`** — diffs current vs `HEAD` to detect new/cancelled/moved/attendee-changed events and conflicts
- **`analyzers/actions_analyzer.py`** — detects all-attendees-declined alerts
- **`state_repo.py`** — git-backed state store at `~/.local/share/claude-personal-assistant`
- **`config_manager.py`** — manages `config/tracking.yaml` (Jira epics, GitHub repos, calendars)
- **`models.py`** — TypedDicts (`CalendarEvent`, `Attendee`, etc.)
- **`utils.py`** — `run_cmd()` subprocess wrapper, `atomic_write_json()`, `atomic_write_text()`
- **`checkpoint.py`** — git add/commit/push on background thread

### UI modules (not unit tested)

- **`dashboard.py`** — main Tkinter window, tab management, window geometry
- **`chat_tab.py`** — Chat tab with Claude Agent SDK streaming
- **`chat_client.py`** — `ClaudeSDKClient` wrapper in background asyncio thread
- **`pages_tab.py`** — discovers `*.html` files in workspace, renders with `tkinterweb`
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
  "pa_workspace": "~/source/personal-assistant-work"
}
```

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

The rename dropped meeting transcript pipeline dependencies, collapsed Assistant+Actions into the Pages tab, and made the workspace path configurable.

## Platform notes

- **Wayland/Mutter:** `winfo_x()`/`winfo_y()` return stale values. Window geometry is tracked via `_grow_up_bottom_y` field. Uses `dock` window type hint. Rejects `(0,0)` position with `height<=1`.
- **Click handling:** Single-click defers 200ms, double-click cancels it (Linux Tkinter fires `<ButtonRelease-1>` before `<Double-1>`).
- **Canvas focus:** Calendar canvas uses `takefocus=True` with explicit click-to-focus binding.

## Autostart

`~/.config/autostart/pa-dashboard.desktop` launches the dashboard on GNOME login. Points to this repo's venv and module.
