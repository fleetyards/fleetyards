import { VehicleSortEnum } from "@/services/fyApi";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";

// The flagship in the header and the list below it read one page, so the two
// share one request: a flagship leads, and the rest follow newest first.
export const SHIPS_LISTED = 10;

export const dashboardHangarParams = {
  perPage: String(SHIPS_LISTED + 1),
  q: {
    sorts: [VehicleSortEnum.FLAGSHIP_DESC, VehicleSortEnum.CREATED_AT_DESC],
  },
};

export const dashboardHangarOptions = { query: liveQuery };
