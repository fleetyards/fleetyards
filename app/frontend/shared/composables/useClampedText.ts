import { useResizeObserver } from "@vueuse/core";
import type { Ref, WatchSource } from "vue";

// Whether a line-clamped element hides text, and whether the reader has asked
// to see it. A clamped element keeps its height when its text changes, so the
// resize observer alone would keep the previous text's answer; the source is
// what marks a new text.
export const useClampedText = (
  el: Ref<HTMLElement | undefined>,
  source: WatchSource,
) => {
  const expanded = ref(false);
  const overflows = ref(false);

  const measure = () => {
    const node = el.value;
    overflows.value = !!node && node.scrollHeight > node.clientHeight + 1;
  };

  useResizeObserver(el, measure);

  onMounted(measure);

  watch(source, async () => {
    expanded.value = false;
    await nextTick();
    measure();
  });

  return { expanded, overflows };
};
