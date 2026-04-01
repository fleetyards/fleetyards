# Remove Bootstrap dependency

## Goal
Fully remove the `bootstrap` npm package by replacing all remaining Bootstrap usage with either Tailwind CSS or custom CSS/components.

## Context
Bootstrap 4.6.0 is used as a CSS-only dependency — no Bootstrap JS. After removing component imports (badge, progress, modal, close, breadcrumb, media, transitions), the remaining Bootstrap usage is:

- **Grid system** (`row`, `col-*`, `offset-*`) — used across ~193 Vue files
- **SCSS tooling** (`functions`, `variables`, `mixins`) — used for grid overrides and breakpoints
- **Reboot** — normalize/reset styles
- **Type** — base typography
- **Utilities** — spacing, display, flex, text helpers (`d-flex`, `d-none`, `text-center`, etc.)
- **Print** — print media styles
- **Custom grid extension** — `col-*-2dot4` for 5-column layouts

## Decisions

### D1 — Tailwind CSS vs custom CSS for grid replacement
**To be decided.** Evaluate Tailwind CSS as the replacement strategy. Considerations:
- Tailwind's grid/flex utilities would replace both Bootstrap grid and utilities in one move
- Tailwind has good Vue/Vite integration
- Large template migration effort either way (~193 files)
- Could adopt incrementally alongside Bootstrap during transition
- Tailwind's responsive breakpoints would need to match the custom breakpoints in `variables.scss`

### D2 — Incremental vs big-bang migration
Recommend incremental: install Tailwind alongside Bootstrap, migrate page by page, remove Bootstrap last.

## What changed (already done)

### Phase 0 — Remove Bootstrap component imports (completed)
1. Removed `transitions`, `breadcrumb`, `badge`, `progress`, `media`, `close`, `modal` imports from `shared/bootstrap-custom.scss`
2. Replaced badge usage in `settings/security/index.vue` with existing `BasePill` component
3. Created `UploadProgress` component to replace Bootstrap progress bars in `ImageUploader`
4. Added breadcrumb separator to `BreadCrumbs` scoped SCSS (was provided by Bootstrap's `_breadcrumb.scss`)
5. Modal, close, and transition styles were already fully custom in scoped SCSS — just removed the imports

## What remains

### Phase 1 — Evaluate Tailwind CSS
1. Set up Tailwind CSS with Vite (`@tailwindcss/vite` plugin)
2. Configure custom breakpoints to match existing ones in `variables.scss`:
   - `xs: 0`, `sm: 576px`, `md: 992px`, `lg: 1500px`, `xl: 2100px`, `xxl: 2800px`, `3xl: 3200px`
3. Configure custom colors/spacing to match existing design tokens
4. Test that Tailwind and Bootstrap can coexist without class conflicts
5. Decide: adopt Tailwind or stick with custom CSS

### Phase 2 — Replace Bootstrap utilities
1. Audit all Bootstrap utility class usage (`d-flex`, `d-none`, `d-block`, `text-center`, `m-*`, `p-*`, `justify-content-*`, `align-items-*`, etc.)
2. Replace with Tailwind equivalents or custom utility classes
3. Remove `@import "bootstrap/scss/utilities"`

### Phase 3 — Replace Bootstrap grid
1. Audit all `row`, `col-*`, `offset-*` usage across ~193 Vue files
2. Categorize layouts:
   - Simple single/two column layouts (easy migration)
   - Multi-column responsive layouts (moderate)
   - Custom `col-*-2dot4` 5-column layouts (need special handling)
3. Replace with Tailwind grid/flex utilities or CSS Grid
   - `row` + `col-*` -> `grid grid-cols-12` + `col-span-*` (or flex equivalents)
   - `col-md-6` -> responsive variants like `md:col-span-6`
   - `col-*-2dot4` -> `grid-cols-5` with `col-span-1`
4. Remove `@import "bootstrap/scss/grid"` and grid overrides

### Phase 4 — Replace Bootstrap base styles
1. `reboot` -> replace with `@tailwindcss/preflight` or `modern-normalize`
2. `type` -> move needed typography rules into project SCSS
3. `print` -> extract the few print rules needed into a standalone file
4. `root` -> remove (CSS custom properties from Bootstrap)
5. `functions`, `variables`, `mixins` -> extract only the breakpoint variables/mixins still needed for project SCSS, or replace with Tailwind's `@screen` / `theme()`

### Phase 5 — Remove Bootstrap package
1. `pnpm remove bootstrap`
2. Delete `stylesheets/shared/bootstrap-custom.scss` and `stylesheets/embed/bootstrap-custom.scss`
3. Clean up `variables.scss` (remove "bootstrap overrides" section)
4. Update entrypoints to remove bootstrap-custom imports

## Key files

| File | Role |
|------|------|
| `app/frontend/stylesheets/shared/bootstrap-custom.scss` | Main Bootstrap import (shared) |
| `app/frontend/stylesheets/embed/bootstrap-custom.scss` | Bootstrap import (embed) |
| `app/frontend/stylesheets/variables.scss` | Bootstrap variable overrides (breakpoints, grid, colors) |
| `app/frontend/entrypoints/frontend.scss` | Frontend entrypoint |
| `app/frontend/entrypoints/admin.scss` | Admin entrypoint |
| `app/frontend/entrypoints/embed.scss` | Embed entrypoint |
| `app/frontend/entrypoints/embed-v2.scss` | Embed v2 entrypoint |
| `app/frontend/entrypoints/docs.scss` | Docs entrypoint |

## Not in scope (deferred)
- **Removing Sass entirely** — Could consider moving to Tailwind-only with CSS variables, but that's a separate effort
- **Component library adoption** — No plan to adopt a UI component library (Headless UI, Radix, etc.)

## Discovery Log
- **2026-04-01** Phase 0 completed: removed all Bootstrap component imports, created UploadProgress component, replaced badge with BasePill

## Progress
- [x] Phase 0 — Remove component imports
- [ ] Phase 1 — Evaluate Tailwind CSS
- [ ] Phase 2 — Replace Bootstrap utilities
- [ ] Phase 3 — Replace Bootstrap grid
- [ ] Phase 4 — Replace Bootstrap base styles
- [ ] Phase 5 — Remove Bootstrap package
