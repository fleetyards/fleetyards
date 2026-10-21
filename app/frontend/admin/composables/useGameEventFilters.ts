import { type GameEventQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useGameEventFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<GameEventQuery>({
    updateCallback,
  });
};
