import { type Ref } from "vue";
import { useResizeObserver } from "@vueuse/core";

// The items an auto-filling grid can show in whole rows, up to `rows` of them,
// so a row is never left with one card in it. Fewer items than one row are
// shown as they are.
export const useFullRows = <T>(
  grid: Readonly<Ref<HTMLElement | null>>,
  items: Readonly<Ref<T[]>>,
  rows: number,
) => {
  const columns = ref(1);

  const measure = () => {
    if (!grid.value) return;

    const tracks = getComputedStyle(grid.value)
      .gridTemplateColumns.split(" ")
      .filter(Boolean).length;

    columns.value = Math.max(tracks, 1);
  };

  useResizeObserver(grid, measure);

  watch(grid, measure);

  return computed(() => {
    const list = items.value;
    if (list.length <= columns.value) return list;

    const fitting = Math.min(list.length, columns.value * rows);

    return list.slice(0, fitting - (fitting % columns.value));
  });
};
