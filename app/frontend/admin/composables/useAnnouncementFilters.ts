import { type AnnouncementQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

export const useAnnouncementFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  return useFilters<AnnouncementQuery>({
    updateCallback,
  });
};
