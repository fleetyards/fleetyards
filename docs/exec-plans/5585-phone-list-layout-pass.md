# Phone list layout pass for the remaining list pages

Working plan for #5585. Decisions live in the issue body. Deleted before the PR merges.

## Goal
Every list page reads on a phone the way the notification centres do: a one-row header, a one-row toolbar, the sort bar, checkboxes only after a long press, and back stepping through every URL change.

## Open questions
- None.

## What changed

### Phase 1: Shared building blocks, notification pages moved onto them
1. `PageActions`: teleports to `#header-right`, renders its slot as buttons on desktop and as a `BtnDropdown` ⋮ on phones (`navigation-header-pinned`), and renders nothing while a selection is active.
2. `MobileSelectionHeader`: wraps `BulkSelectionBar`, teleports it into `#header-left` while selecting on a phone, with the ✕ and the compact count; renders the plain bar in place otherwise.
3. `useRoutedSelection` (prototype restored): on a phone, opening a detail pushes `?<key>=<id>`; back closes it; a reload reopens it.
4. Both notification pages use 1–3. Mark-read moves to a watcher on the open record so a URL-driven open counts as reading it.

### Phase 2: History follows the URL
1. `useFilters` pushes instead of replacing.
2. Consecutive search keystrokes collapse into one entry: the first change of a burst pushes, later ones in the same burst replace.
3. Check that the sort chips, tab links and paginator still push (they do today).

### Phase 3: Long press on tables
1. `BaseTable` hides its checkbox column on phones until a long press on a row starts a selection; a tap toggles while selecting.
2. Its own `selected-actions`/`BulkActions` bar takes the header the way `MobileSelectionHeader` does.

### Phase 4: Tier 1 pages (full pattern)
hangar, wishlist, hangar inventory detail, fleet inventory detail, hangar cargo, admin models, admin imports, admin supporter contributions, admin fleets.

### Phase 5: Tier 2 pages (header ⋮ and one-row toolbar)
fleet members, fleet events, fleet logistics, fleet missions, hangar inventories, ships, public hangar and wishlist (toolbar only).

### Phase 6: Tier 3 checks and hero headings
Catalogue lists, fleet directory, fleet blueprints, buybacks, single-button admin lists: verify the toolbar fits on one row at 390px; decide the hero heading per page (keep it only where it adds context).

## Intent Verification

- [ ] **One-row header** on every touched page at 390px: back, search, ⋮ (or nothing when there are no actions)
- [ ] **One-row toolbar** under it, sort bar below
- [ ] **No checkboxes on phones** until a long press, on card rows and tables alike; the bulk bar then owns the header
- [ ] **Back** steps through filters, sort, tab, page turns and an open full-screen detail; selection mode adds nothing
- [ ] **Desktop unchanged** on every touched page

## Key files

| File | Role |
|------|------|
| `app/frontend/shared/composables/useRoutedSelection.ts` | Detail as a history entry on phones |
| `app/frontend/shared/composables/useSelectionMode.ts` | Phone selection mode |
| `app/frontend/shared/composables/useFilters.ts` | Filter navigation (replace → push) |
| `app/frontend/shared/components/BulkSelectionBar` | Bulk bar, `compact` count |
| `app/frontend/shared/components/base/Table` | Table selection (`selectable`, `selected-actions`, `BulkActions`) |
| `app/frontend/shared/components/AppNavigation/Header/index.scss` | `navigation-header-pinned` / `-takeover` hooks |
| `app/frontend/{frontend,admin}/pages/notifications.vue` | First consumers of the extracted pieces |

## Not in scope (deferred)
- None yet.

## Discovery Log

- **2026-10-11** Plan created from the page survey in the issue. `BaseTable` carries its own selection model and bulk bar, separate from `useBulkSelection`, hence Phase 3.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
- [ ] Phase 4
- [ ] Phase 5
- [ ] Phase 6
