# FilteredList shows a 400 as "Server Error"

## Goal
Give a request the API refused to validate its own screen, so a bad sort key or
a malformed filter no longer reads as a server outage, and offer the reader a
way back to the list.

## Context
`errorTypeFrom` (`app/frontend/shared/utils/ErrorTypes.ts`) classified 403, 404
and unanswered requests, and returned `ERROR` for every other status.
`FilteredList` and `AsyncData` render `ServerError` for `ERROR`, so a 400 from
request validation showed "Server Error". The members-list `s` sort bug only
surfaced through a user report for that reason.

On a list the params that fail validation come from the route: the filter keys,
the sort `s`, and pagination. `useFilters().resetFilter()` already clears all of
them while keeping the view state (`tab`, `view`, `direction`).

Resolves #5158

## Decisions

### D1 — Only a 400 is a client error
Request validation answers 400. A 422 is a model validation failure on a write,
and 401/429 have nothing to do with the request's params, so they stay on the
generic error screen. Adding a status later is one line in `errorTypeFrom`.

### D2 — One `ClientError` component, reset optional
`ClientError` renders the generic "could not process this request" text. Given a
`reset` callback it switches to "This filter or sort isn't valid" and shows a
Reset Filter button. `AsyncData` has no filter to clear, so it renders it
without one.

### D3 — Reset through `useFilters`
`FilteredList` calls `resetFilter()` and also drops the persisted filter for the
list from the filters store, so the stored bad filter is not reapplied. The
button only shows when the route carries something beyond view state
(`hasResettableQuery`); a 400 with nothing to clear gets the generic text.

## What changed
1. `ErrorTypesEnum.CLIENT_ERROR`; `errorTypeFrom` maps 400 to it.
2. `app/frontend/shared/components/ClientError/index.vue` — new error box.
3. `AsyncData` and `FilteredList` render `ClientError` for `CLIENT_ERROR`;
   `FilteredList` passes a reset.
4. `useFilters` exposes `hasResettableQuery`.
5. `headlines.invalidRequest`, `texts.invalidRequest`,
   `texts.invalidListRequest` in all 7 locales.

## Intent Verification

- [x] **A 400 renders a different screen than a 500** — `FilteredList` and
  `AsyncData` specs
- [x] **The reset clears filter, sort and page but keeps the view** — a route
  with `s`, a filter, `page` and `tab` ends up with only `tab`
- [x] **No reset button when there is nothing to clear**

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/utils/ErrorTypes.ts` | Status to error type |
| `app/frontend/shared/components/AsyncData.types.ts` | `ErrorTypesEnum` |
| `app/frontend/shared/components/ClientError/index.vue` | Client error screen |
| `app/frontend/shared/components/FilteredList/index.vue` | List error states and reset |
| `app/frontend/shared/components/AsyncData.vue` | Record error states |
| `app/frontend/shared/composables/useFilters.ts` | `resetFilter`, `hasResettableQuery` |

## Progress
- [x] Classifier and enum
- [x] ClientError component and translations
- [x] FilteredList and AsyncData wiring with specs
