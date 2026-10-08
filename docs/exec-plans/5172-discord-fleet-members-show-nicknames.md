# Discord /fleet members: show fleet nicknames

Working plan for #5172. Decisions live in the issue body. Deleted before the PR merges.

## Goal
`/fleet members` names each member the way the web roster does: the nickname first where one is set, the username beside it.

## What changed

### Phase 1 — Roster lines
1. A line reads `• Nickname (username) — Role`, matching `Fleets/MemberName` on the web.
2. Nickname and username are Markdown-escaped. A nickname is free text, and a username with underscores already renders in italics.
3. A nickname is capped so ten lines stay short. Whole lines are dropped from the end if the message would still exceed 2000 UTF-16 units, and the "more" line counts them.

## Intent Verification

- [ ] **Nickname shown** — a member with a nickname shows it alongside the username
- [ ] **Within limits** — a full page of maximum-length nicknames and roles stays under 2000 characters

## Key files

| File | Role |
|------|------|
| `lib/discord/commands/fleet_members.rb` | The command |
| `test/lib/discord/commands/fleet_members_test.rb` | Its tests |
| `lib/discord/markdown.rb`, `lib/discord/message_length.rb` | Escape and length helpers |

## Discovery Log

- **2026-10-08** The roster always printed `user.username`, not an RSI handle. Ordering stays by username, so a lookup by username still works.

## Progress
- [ ] Phase 1
