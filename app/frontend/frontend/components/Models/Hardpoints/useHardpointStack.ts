import type { Ref } from "vue";
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
  const density = inject<Ref<"compact" | "expanded">>(
    "hardpointDensity",
    ref("compact"),
  );

  const expanded = ref(density.value === "expanded");

  watch(density, (value) => {
    expanded.value = value === "expanded";
  });

  const isGroup = computed(() => hardpoints().length > 1);

  const toggleExpanded = () => {
    expanded.value = !expanded.value;
  };

  // Only a real stack (>1 identical mount) collapses to a summary row; single
  // items always render, even when the global density is "expanded".
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
