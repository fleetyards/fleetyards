import type { ComputedRef, InjectionKey } from "vue";

/**
 * True for the rows inside a flyout — the panel a section opens beside the
 * collapsed rail.
 *
 * A flyout labels its rows while the rail behind it does not, so those rows
 * have to ignore the store's slim flag. They cannot simply be told to: they are
 * slot content the *caller* wrote, so the row that opens the panel never holds
 * them. It announces the expansion instead, and every row underneath reads it.
 */
export const NAV_EXPANDED: InjectionKey<ComputedRef<boolean>> =
  Symbol("navExpanded");

/**
 * The panels that are open, outermost first: a section's panel, and the panel
 * of a sub-section inside it.
 *
 * Shared rather than per-row because closing the others is not something a row
 * can do on its own: a pinned panel outlives the pointer that opened it, so two
 * clicks would otherwise leave two panels floating over the page at whatever
 * height their rows happen to sit at. A path rather than one panel, so opening
 * a sub-section's panel keeps the one it was opened from.
 */
export const openFlyout = ref<symbol[]>([]);

/**
 * The panels a row sits inside, outermost first -- the path its own panel
 * extends when it opens.
 */
export const FLYOUT_PATH: InjectionKey<ComputedRef<symbol[]>> =
  Symbol("flyoutPath");
