import { type GameMissionQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useMissionFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<GameMissionQuery>({
    updateCallback,
  });
};
