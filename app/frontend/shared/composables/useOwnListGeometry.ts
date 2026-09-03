import { provideListGeometry } from "@/shared/composables/useListGeometry";
import { useListGeometryStore } from "@/shared/stores/listGeometry";
import type { ComputedRef, MaybeRefOrGetter } from "vue";

// For a page that draws a list of its own with no FilteredList around it. It
// becomes that list's frame, so the placeholders it puts up can read the same
// two things a framed list's read: how many records the answer is expected to
// hold, and what one of them measured last time.
//
// The count is this list's own high-water mark, because there is no page size
// to read a bound off - an unpaginated grid holds what it holds, and what it
// held last time is the only honest reading of that. The height comes back
// through the geometry, which whatever drew the records reports into: Grid and
// BaseTable both do it already.
export const useOwnListGeometry = (
  name: string,
  records: MaybeRefOrGetter<unknown[]>,
  loading: MaybeRefOrGetter<boolean>,
  // Where nothing is known yet. Small on purpose: a page of placeholders
  // reserved for a reader who keeps two of something is a screenful of nothing.
  fallback = 3,
): { count: ComputedRef<number> } => {
  const store = useListGeometryStore();

  // Once the answer is in, whatever it held - including nothing. A list read
  // mid-load is empty for a reason that says nothing about how much it holds.
  watch(
    [() => toValue(records).length, () => toValue(loading)],
    ([count, busy]) => {
      if (!busy) {
        store.recordCount(name, count);
      }
    },
    { immediate: true },
  );

  const count = computed(() => store.countByKey(name) ?? fallback);

  // The page is showing a spinner of its own over these placeholders, so a list
  // rendered inside them knows not to put up a second.
  provideListGeometry(
    name,
    count,
    computed(() => toValue(loading)),
  );

  return { count };
};
