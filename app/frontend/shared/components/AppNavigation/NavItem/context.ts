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
 * The elements of the open panels, so a row can ask where the panel it would
 * replace actually is.
 */
export const flyoutPanels = new Map<symbol, HTMLElement>();

export type PointerPosition = { x: number; y: number };

// A pointer rarely runs straight, and the row it is after can sit near the panel's
// lower edge, so the triangle is opened up past the panel's own height.
const AIM_SLACK = 60;

/**
 * Whether a pointer that started at `from` is on its way to the panel: `to` lies
 * in the triangle between `from` and the panel's near edge. The rows between a
 * section's row and its panel are crossed on that way, and must not take over.
 *
 * `from` has to stay where the pointer started. Sampled from one moment to the
 * next, a slow pointer moves a pixel or two at a time, too little to have a
 * direction.
 */
export const aimsAtPanel = (
  from: PointerPosition,
  to: PointerPosition,
  panel: Pick<DOMRect, "left" | "top" | "bottom">,
) => {
  const reach = panel.left - from.x;
  const travelled = to.x - from.x;

  if (reach <= 0 || travelled <= 0 || travelled > reach) {
    return false;
  }

  const progress = travelled / reach;

  return (
    to.y >= from.y + (panel.top - AIM_SLACK - from.y) * progress &&
    to.y <= from.y + (panel.bottom + AIM_SLACK - from.y) * progress
  );
};

/**
 * The panels a row sits inside, outermost first -- the path its own panel
 * extends when it opens.
 */
export const FLYOUT_PATH: InjectionKey<ComputedRef<symbol[]>> =
  Symbol("flyoutPath");
