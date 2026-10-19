# Ship filter redesign

Implement the compact filter proposal in an isolated worktree.

- [x] Copy the SCU range changes and set up the worktree.
- [x] Group ship filters into Ship, Capacity & dimensions, Price, and Ownership.
- [x] Add a compact active-filter row: two chips, combined ranges, overflow count.
- [x] Show all selections in the filter panel and only the count on mobile.
- [x] Verify URL navigation, range removal, existing lists, and desktop layout.

## Key files

`FilteredList`, `ActiveFilters`, `FilterGroup`, the three ship filter forms,
and `useShipFilterSummary`.

## Validation

55 backend tests and 55 frontend tests passed. TypeScript checks passed.
Browser checked the compact bar, overflow opening, combined range removal,
and back navigation on the ship catalog. Responsive mobile layout still needs
a visual check. Ruby lint passed. The full frontend lint scan found typed lint errors in
the new summary code; those were fixed and the affected components passed
a focused lint run. Full frontend formatting passed.
