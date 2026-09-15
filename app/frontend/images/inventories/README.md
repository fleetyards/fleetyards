# Inventory Pictures

The art offered when an inventory is created or edited, and the art one falls
back to when nobody has picked anything.

Drop a WebP file in here and it joins the picker — there is no list to edit and
no key to register. Recommended ~1600×500, the same banner shape the mission and
contract covers use; smaller is fine. A `.jpg` beside a `.webp` of the same name
is treated as the same picture in a second format, and the WebP wins.

Unlike missions and contracts, these are not filed under a type: an inventory is
a place, not a kind of job, so the picker shows every picture at once and renders
no filter.

Until this folder is full enough to choose from, `usePresetImages` also lends the
picker a handful of page backdrops the app already ships (`bg-hangar`, `bg-1`,
`bg-2`, `bg-3`, `bg-5`, `bg-9`). A file in here always outranks one of those with
the same name.

Two things never take a picture from this folder:

- **A ship's hold**, which is shown as its ship. That is the one thing about the
  hold a reader already recognises, which is also why a ship's hold offers no
  picture of its own to pick.
- **An inventory that carries an upload**, which is shown as what was uploaded.

Anything else with no picture picked takes one from here, chosen by hashing its
name — so two inventories side by side differ, and one keeps its picture across
reloads. Adding art therefore reshuffles which inventory falls back to what; that
is the intent, not a regression. An inventory whose picture was actually picked
is unaffected.
