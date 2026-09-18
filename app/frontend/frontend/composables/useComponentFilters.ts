import { type ComponentQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useComponentFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<ComponentQuery>({ updateCallback });
};
