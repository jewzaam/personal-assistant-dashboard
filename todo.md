# TODO

## Remove git-backed state repo dependency

The state repo (`state_repo.py`) uses a local git repo at `~/.local/share/claude-personal-assistant/` to store JSON snapshots and detect changes via `git diff HEAD`. This is heavy for what it provides:

- **Change detection** was the only consumer (the "Changes" bar, now removed). The calendar bell now tracks seen event IDs in memory instead of diffing git.
- **State persistence** is just writing JSON files to a directory — git adds no value over plain file writes.
- **Rollback** is unnecessary — state is cached API responses that can be re-fetched.

**To remove:**
- Replace `init_repo()` with plain `mkdir -p`
- Replace `commit_state()` with a no-op or remove callers
- Replace `get_file_at_last_commit()` with in-memory previous-snapshot comparison if change detection is ever needed again
- Remove `git` subprocess calls from `state_repo.py`
- Remove git identity setup from CI workflows

**Priority:** Low. The git dependency is inert — present but not causing issues beyond unnecessary complexity.
