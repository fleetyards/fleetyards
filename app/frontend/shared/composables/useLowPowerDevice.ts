import { isMobileWidth } from "@/shared/stores/mobile";
import { useMobile } from "@/shared/composables/useMobile";

// A touch screen as the main pointer: a tablet in landscape is no phone by
// width, but it runs out of memory on the same 3D scenes.
const coarsePointer = () =>
  typeof window !== "undefined" &&
  typeof window.matchMedia === "function" &&
  window.matchMedia("(pointer: coarse)").matches;

// For what a device can hold rather than how the page is laid out: the 3D
// viewer's render settings, its decoder and its size guard.
export const isLowPowerDevice = () => isMobileWidth() || coarsePointer();

export const useLowPowerDevice = () => {
  const mobile = useMobile();

  return computed(() => mobile.value || coarsePointer());
};
