# RSI Profile Writes via the Sync Extension

**Date:** 2026-10-07
**Status:** Reference; in use for handle verification (#5460) and fleet verification (#5465)

How the FleetYards Sync extension (fleetyards/sync) writes to a user's RSI profile, and what RSI does and does not give back. Read it before letting the extension write anything else on RSI.

## Writing the bio

RSI's settings page saves the bio with one request, sent with the user's RSI session (cookies plus `X-Rsi-Token`):

```
POST https://robertsspaceindustries.com/api/settings/UpdateField
{"pageId": "my_profile", "fieldId": "biography", "value": "<the whole bio>"}
```

- `value` replaces the whole bio. There is no append.
- RSI answers some refusals with HTTP 200 and `success: 0` in the body, so a 200 alone is not success.
- The editor caps the bio at 1024 characters, counted as JavaScript string length.
- The settings page has reCAPTCHA Enterprise loaded, but only the store checkout uses it. The bio save takes no captcha token.
- The editor lives at `/account/settings/profile`. The old `/account/profile` URL only lands on the settings overview.

## Reading the bio back

The settings API has no read we could find for the extension to call (the editor's data comes from `/api/settings/Page`, which was not captured). The extension reads the bio from the public citizen page instead, `/en/citizens/<handle>`, the same page `Rsi::CitizenPage` checks:

- The bio sits in `.entry.bio .value`, HTML-escaped, with `<br />` for each line break, wrapped in template indentation.
- A plain-text bio reads back exactly: on a real page, the parsed text matched what the settings page sends on save, character for character.
- A bio edit shows on the citizen page right away. Checking straight after the write is enough.
- Leading and trailing whitespace cannot be told apart from the template's, so it is lost.

## Why the token is removed, not the bio restored

Because the read is a rendering of the bio rather than the bio itself, writing back a saved copy could overwrite the user's text with a near copy of it. The extension therefore removes exactly the `\n\n<token>` it appended, and refuses to write at all (422) when the bio holds markup or entities it cannot turn back into text, or when the bio entry's markup no longer matches.

Anything the extension writes later should follow the same rule: change only what it added, and refuse when it cannot read the current value exactly. The org page fields render as formatted text on the public page, so the org write reads them from the editor's raw source instead (below).

## Writing an org page field

The org editor lives at `/en/orgs/<SID>/admin/content`. It saves one field per request, whole value, with the same session headers as the bio:

```
POST https://robertsspaceindustries.com/api/orgs/saveDraft
{"symbol": "<SID>", "<field>": "<the whole text>"}
```

- The fields are `introduction`, `history`, `manifesto` and `charter`. The editor caps `introduction` at 300 characters; the others show no limit.
- A save only changes the org's draft. `POST /api/orgs/publishDraft {"symbol": "<SID>"}` makes it live, and it takes no field: it publishes the **whole** draft, including other officers' unpublished edits.
- `FleetRsiVerification` reads the whole public org page, so the token can go in any field. The extension uses `history`.

### Reading the raw text

The admin content page renders the draft's raw text server-side, in `<textarea name="introduction|history|manifesto|charter">`, so the extension reads a field exactly before writing it, formatting included. No GraphQL request carries it; the page is older than RSI's GraphQL.

### Edit rights

Without content rights the admin page still answers 200 and draws a client-side "Restricted area" screen, but the server-rendered `<title>` already starts with "Access denied". That title is the extension's no-rights signal (403 to the site). RSI exposes no list of orgs an account can edit that we found.

### Unpublished drafts

The page shows no marker for a pending draft (Save draft, Preview, Publish and Erase draft are always there). Because publishing takes everything, the extension writes only when nothing is pending: it compares each section of the draft, rendered at `/en/orgs/<SID>/admin/preview`, with the same section of the public `/orgs/<SID>` page, with `FLEETYARDS-…` tokens removed from both, and refuses (409) on any difference. It checks again right before publishing, and when it rolls a save back it does so only while the field still holds exactly what it saved. Requests for one org run one at a time, so a write and a remove cannot interleave.

Comparing per section matters: an earlier build compared the pages as a whole, missed a pending edit in another section, and published another officer's unfinished changes.

## Talking to the extension

The site posts `{direction: "fy", message: JSON}` on `window`. The extension answers with `{direction: "fy-sync", message: JSON}`, matched by `action`. The health check answers with `payload: {version, actions}`, and the site offers a feature only when its action is in that list. Older versions answer with no payload, and an unknown action gets a 500 "Unknown Action".

Anything on the page can post into this channel, answers included. Nothing the extension reports is proof to the server: verification still reads the public page server-side.
