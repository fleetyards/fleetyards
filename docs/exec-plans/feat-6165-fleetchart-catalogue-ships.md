# Add catalogue ships to a free fleetchart arrangement

Working plan for this branch of #6165. Decisions live in the issue body.

## Goal

Try out ships you don't own in a Free arrangement, saved with the layout and marked as not owned.

## Steps

1. API: `catalogue_placements` on a layout, and the models in the shared response.
2. Chart: a catalogue ship is a copy of its model with its own ID, so every chart feature works on it.
3. Search panel to add ships, a mark on the ship, and a control to remove it.
4. Saving, reopening and the shared page.

## Progress

- [ ] API
- [ ] Chart
- [ ] Panel, mark and removal
- [ ] Saving and sharing
