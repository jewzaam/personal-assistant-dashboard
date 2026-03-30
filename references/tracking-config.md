# Tracking Configuration Reference

The PA uses `config/tracking.yaml` in the state repo to know what to monitor.
The state repo defaults to `~/.local/share/pa-state/`.

## File Format

```yaml
# Jira epics to track
jira:
  - key: ANSTRAT-1900      # Jira issue key
    tier: active            # "active" = full depth (children, blockers, direction changes)
  - key: ANSTRAT-2100
    tier: awareness          # "awareness" = summary only, drill-down on demand

# GitHub repositories to monitor for PRs
github:
  repos:
    - owner/repo-name       # GitHub owner/repo format

# Google Calendars to collect events from
calendars:
  - primary                  # "primary" = your main Google Calendar
  - eng@group.calendar.google.com  # shared calendar by ID
```

## Calendar IDs

- `primary` — your main Google Calendar (the one tied to your account)
- For other calendars, use the full calendar ID (usually a long `...@group.calendar.google.com` address)
- Run `pa track calendars` to list all calendars available to your account with their IDs

### Which calendars to add

Add calendars that contain **meetings you attend or need awareness of**. Skip:
- Reminder-only calendars (birthdays, tasks, holidays)
- Personal calendars imported from other accounts (unless you want work awareness of personal conflicts)
- Calendars with event types like `workingLocation` that don't represent actual meetings

The collector fetches all event types from each calendar. Filtering by event type (e.g., excluding `workingLocation`, `outOfOffice`) is planned but not yet implemented.

## Jira Tiers

| Tier | What you get | When to use |
|------|-------------|-------------|
| `awareness` | Summary: status, assignee, priority of the epic only | General visibility — "is this on track?" |
| `active` | Full hierarchy: epic + all child stories/tasks. Detects status changes, direction changes, blockers, reassignments | You're the architect/owner and need to catch problems early |

## CLI Commands

```bash
# State repo
pa state init                   # initialize the state repo
pa state status                 # show uncommitted changes
pa state commit -m "message"    # commit current state

# Calendar management
pa track calendars              # list available Google calendars
pa track calendar <id>          # add a calendar
pa track uncalendar <id>        # remove a calendar

# Jira tracking
pa track add <KEY>              # add with default tier (awareness)
pa track add <KEY> --tier active
pa track remove <KEY>

# GitHub repos
pa track repo <owner/repo>

# View current config
pa track list

# Data collection and analysis
pa collect calendar             # pull events from tracked calendars
pa collect calendar --days 14   # look ahead 14 days (default: 7)
pa analyze calendar             # show changes since last commit

# Dashboard
pa gui                          # launch the calendar dashboard
```

## Dashboard

The `pa gui` command opens a Canvas-based calendar day view.

### Navigation
- **Left/Right arrows** or **keyboard arrows** to change day
- **Today button** to jump back to today
- **Refresh** to re-collect from Google Calendar
- **Window resize** auto-rescales the view

### Visual Encoding

**Fill color = event category:**
- Teal green = regular meeting
- Steel blue = 1:1
- Red = conflict (overlapping events needing action)

**Border = your response status:**
- Solid white = accepted
- Dashed white = tentative
- No border = no response yet

**Attendee count** shown as `(accepted/total)` after the title.

### Right-Click Context Menu

Right-click any event block to change your response:
- **Accepted events**: Maybe | Decline
- **No response**: Accept | Maybe | Decline
- **Tentative events**: Accept | Decline

Updates are sent to Google Calendar via GWS CLI and the view refreshes automatically.
