import type { FleetchartPlacement as ApiPlacement } from "@/services/fyApi";
import {
  FleetchartFacings,
  FleetchartShipStates,
  FleetchartViewpoints,
  type FleetchartPlacements,
} from "@/shared/stores/fleetchart";

export type FleetchartPlacementInput = ApiPlacement;

// The API sends what was never set as null, where a placement leaves it out.
export const placementsFromLayout = (
  placements: ApiPlacement[],
): FleetchartPlacements =>
  Object.fromEntries(
    placements.map(
      ({ vehicleId, x, y, facing, viewpoint, state, order, groupId }) => [
        vehicleId,
        {
          x,
          y,
          ...(facing ? { facing: facing as FleetchartFacings } : {}),
          ...(viewpoint
            ? { viewpoint: viewpoint as FleetchartViewpoints }
            : {}),
          ...(state ? { state: state as FleetchartShipStates } : {}),
          ...(order === null || order === undefined ? {} : { order }),
          ...(groupId ? { groupId } : {}),
        },
      ],
    ),
  );
