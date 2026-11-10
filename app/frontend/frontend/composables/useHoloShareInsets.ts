import { useResizeObserver } from "@vueuse/core";
import type { HoloFrameInsets } from "@/shared/components/HoloViewer/frameInsets";

type Element = MaybeRefOrGetter<HTMLElement | null | undefined>;

/**
 * Insets that leave a holo the right-hand `share` of the box it is laid over,
 * at the holo's full height: a holo starting further left than that fades in
 * under the controls, and only its clear part is for the model. Nothing while
 * the holo is hidden.
 */
export const useHoloShareInsets = (
  holo: Element,
  container: Element,
  share: number,
) => {
  const insets = ref<HoloFrameInsets>();

  const measure = () => {
    const box = toValue(holo)?.getBoundingClientRect();
    const outer = toValue(container)?.getBoundingClientRect();

    if (!box?.width || !box.height || !outer?.width) {
      insets.value = undefined;
      return;
    }

    const start = outer.left + outer.width * (1 - share);
    const left = Math.min(Math.max(start - box.left, 0), box.width);

    insets.value = { top: 0, right: 0, bottom: 0, left };
  };

  useResizeObserver(
    () => [toValue(holo), toValue(container)].filter(Boolean),
    measure,
  );

  return insets;
};
