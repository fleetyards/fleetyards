import type { Hardpoint } from "@/services/fyApi";

/**
 * A hardpoint row's stack: identical hardpoints shown as one row, split into
 * their own rows on request. A split row is `collapsible` and folds the stack
 * back through its parent's `fold`.
 */
export const useHardpointStack = (
  hardpoints: () => Hardpoint[],
  collapsible: () => boolean,
  fold: () => void,
) => {
  const expanded = ref(false);

  const isGroup = computed(() => hardpoints().length > 1);

  const toggleExpanded = () => {
    expanded.value = !expanded.value;
  };

  // Only a real stack (>1 identical mount) collapses to a summary row.
  const stackExpanded = computed(() => isGroup.value && expanded.value);

  const onRowClick = () => {
    if (collapsible()) {
      fold();
    } else if (isGroup.value) {
      toggleExpanded();
    }
  };

  return { isGroup, stackExpanded, toggleExpanded, onRowClick };
};
