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
 * The section whose panel is open, if any.
 *
 * Shared rather than per-row because closing the others is not something a row
 * can do on its own: a pinned panel outlives the pointer that opened it, so two
 * clicks would otherwise leave two panels floating over the page at whatever
 * height their rows happen to sit at.
 */
export const openFlyout = ref<symbol | null>(null);
