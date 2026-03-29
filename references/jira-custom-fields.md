# Jira Custom Fields Reference

> Source: `~/.claude/skills/review-sdp/references/jira-access.md` (captured 2026-03-29; source skill may be deleted)

## Access Methods (Priority Order)

1. **Atlassian MCP plugin** (preferred): `mcp__plugin_atlassian_atlassian__getJiraIssue`
   - Must explicitly request custom fields in the `fields` array
   - Example: `fields: ["summary", "description", "status", "customfield_10718"]`
   - Use `responseContentFormat: "markdown"` for standard fields
   - **Do NOT use `fields: ["*all"]`** — returns 100KB+ responses

2. **Jira CLI**: `jira issue view <ID> --plain` (includes custom fields automatically)

3. **GitHub CLI**: `gh` commands if data is accessible through linked issues

## Known Custom Fields

| Field ID | Name | Notes |
|----------|------|-------|
| `customfield_10718` | Acceptance Criteria | ANSTRAT features. NOT in description field. |

## Custom Field Gotchas

- **Default API response only returns standard fields** — custom fields are NOT included automatically
- **Must explicitly request custom fields by field ID** in the `fields` array
- **`responseContentFormat: "markdown"` only converts standard rich-text fields** (like `description`). Custom fields like `customfield_10718` are still returned as ADF JSON regardless.

## ADF (Atlassian Document Format) Parsing

Custom rich-text fields return ADF JSON, not markdown. Key node types:

- `heading` nodes with `attrs.level` — category headers
- `orderedList` nodes with `attrs.order` — numbered lists
- `listItem` nodes — individual items
- `paragraph` nodes — text content within list items

### Parsing Approach

- Extract headings (categories), numbered items (criteria), nested items (sub-criteria)
- Assign sequential IDs per category: AC1, AC2, etc.
- Sub-bullets become AC1.1, AC1.2, etc.

## Field Discovery

The prescriptive approach (known field IDs) is preferred over dynamic discovery. However, for discovering unknown custom fields:

1. Get the issue type ID from the issue (`issuetype.id` from `getJiraIssue`)
2. Call `getJiraIssueTypeMetaWithFields` with the project key and issue type ID
3. Search returned fields for the desired field name, note its `fieldId`
4. Call `getJiraIssue` with the discovered field ID in the `fields` array
