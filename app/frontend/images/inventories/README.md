# Inventory Placeholder Images

The picture an inventory is shown with when it carries none of its own and no
ship lends it one. A ship's hold is drawn as its ship; everything else — a
hand-made hangar inventory, a fleet inventory — takes one of these.

Drop in WebP files (recommended ~1600×500 for the panel; smaller is fine). The
filename is the only thing that matters — there is no list to extend:

    placeholder-1.webp
    placeholder-2.webp
    crates.webp
    ...

Every file in this folder joins the rotation. Which one an inventory gets is
spread across them by its name, so two inventories side by side differ and one
keeps its picture across reloads and between the panel and the form that edits
it. Adding art therefore reshuffles which inventory shows what — that is the
intent, not a regression.

`webp` wins over `png`, which wins over `jpg`/`jpeg`, for the same stem: two
files named `crates.webp` and `crates.jpg` are one picture in two formats, not
two entries in the rotation.

This folder is not the only source: `useInventoryImage` also pulls a curated set
of backdrops the app already ships, so the rotation is never empty just because
nothing has been dropped in here. The generic store-image placeholder is only
reached if both are empty.
