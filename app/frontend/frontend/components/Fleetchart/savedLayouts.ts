import type {
  FleetchartCataloguePlacement as ApiCataloguePlacement,
  FleetchartPlacement as ApiPlacement,
} from "@/services/fyApi";
import {
  FleetchartFacings,
  FleetchartShipStates,
  FleetchartViewpoints,
  type FleetchartPlacements,
} from "@/shared/stores/fleetchart";

export type FleetchartPlacementInput = ApiPlacement;

// Ships without an order stack by when they are drawn, which follows the chart's
// sort. A saved layout is opened under other settings, so it records the stacking
// as it is: by explicit order first, then by drawing order.
export const stackingOrders = (
  drawnIds: string[],
  orderOf: (id: string) => number,
): Record<string, number> =>
  Object.fromEntries(
    drawnIds
      .map((id, drawn) => ({ id, drawn, order: orderOf(id) }))
      .sort((a, b) => a.order - b.order || a.drawn - b.drawn)
      .map(({ id }, index) => [id, index]),
  );

type SavedPlacement = Omit<ApiPlacement, "vehicleId">;

// The API sends what was never set as null, where a placement leaves it out.
const placementFrom = ({
  x,
  y,
  facing,
  viewpoint,
  state,
  order,
  groupId,
  heading,
}: SavedPlacement) => ({
  x,
  y,
  ...(facing ? { facing: facing as FleetchartFacings } : {}),
  ...(viewpoint ? { viewpoint: viewpoint as FleetchartViewpoints } : {}),
  ...(state ? { state: state as FleetchartShipStates } : {}),
  ...(order === null || order === undefined ? {} : { order }),
  ...(groupId ? { groupId } : {}),
  ...(heading ? { heading } : {}),
});

export const placementsFromLayout = (
  placements: ApiPlacement[],
  cataloguePlacements: ApiCataloguePlacement[] = [],
): FleetchartPlacements => ({
  ...Object.fromEntries(
    placements.map((placement) => [
      placement.vehicleId,
      placementFrom(placement),
    ]),
  ),
  ...Object.fromEntries(
    cataloguePlacements.map((placement) => [
      placement.id,
      { ...placementFrom(placement), modelId: placement.modelId },
    ]),
  ),
});
