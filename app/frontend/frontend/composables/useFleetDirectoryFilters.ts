import { type FleetDirectoryQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useFleetDirectoryFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<FleetDirectoryQuery>({ updateCallback });
};
