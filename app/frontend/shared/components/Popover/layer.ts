import { type InjectionKey } from "vue";

// Above the page, below AppModal (1050): a card opened from the page must not
// cover a modal that later opens over it.
export const POPOVER_BASE_LAYER = 1040;

// The z-index of the overlay a popover's trigger sits in. The overlay provides
// its own layer and the popover places itself one above it, so a card opened
// from a hardpoint row inside a modal is not painted underneath that modal.
export const popoverLayerKey: InjectionKey<number> = Symbol("popoverLayer");
