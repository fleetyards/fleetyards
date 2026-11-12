import {
  createFleetSquadronFlightShip,
  createFleetSquadronFlightSlot,
  createMissionShip,
  createMissionSlot,
  destroyFleetSquadronFlightShip,
  destroyFleetSquadronFlightSlot,
  destroyMissionShip,
  destroyMissionSlot,
  duplicateMissionShip,
  sortFleetSquadronFlightShips,
  sortFleetSquadronFlightSlots,
  sortMissionShips,
  sortMissionSlots,
  updateFleetSquadronFlightShip,
  updateFleetSquadronFlightSlot,
  updateMissionShip,
  updateMissionSlot,
  type MissionShipCreateInput,
  type MissionShipUpdateInput,
  type MissionSlotCreateInput,
  type MissionSlotSortInput,
  type MissionSlotUpdateInput,
} from "@/services/fyApi";

// Where a lineup of ships and slots lives: a template team, or the team a
// squadron's flight keeps. Both are edited with the same components and the
// same payloads; only the addresses differ.
export interface LineupScope {
  fleetSlug: string;
  teamId: string;
  missionSlug?: string;
  squadronSlug?: string;
  flightId?: string;
}

export const isFlightScope = (scope: LineupScope) =>
  !!scope.flightId && !!scope.squadronSlug;

export const useLineupApi = (scope: MaybeRefOrGetter<LineupScope>) => {
  const isPending = ref(false);

  const track = async <T>(request: Promise<T>) => {
    isPending.value = true;
    try {
      return await request;
    } finally {
      isPending.value = false;
    }
  };

  const flight = () => {
    const value = toValue(scope);

    return isFlightScope(value)
      ? ([value.fleetSlug, value.squadronSlug!, value.flightId!] as const)
      : undefined;
  };

  const template = () => {
    const value = toValue(scope);

    return [value.fleetSlug, value.missionSlug ?? "", value.teamId] as const;
  };

  const createShip = (data: MissionShipCreateInput) => {
    const target = flight();
    return track(
      target
        ? createFleetSquadronFlightShip(...target, data)
        : createMissionShip(...template(), data),
    );
  };

  const updateShip = (id: string, data: MissionShipUpdateInput) => {
    const target = flight();
    return track(
      target
        ? updateFleetSquadronFlightShip(...target, id, data)
        : updateMissionShip(...template(), id, data),
    );
  };

  const destroyShip = (id: string) => {
    const target = flight();
    return track(
      target
        ? destroyFleetSquadronFlightShip(...target, id)
        : destroyMissionShip(...template(), id),
    );
  };

  // A flight's ship is one member's own and is in the flight once, so only a
  // template's spot is copied.
  const duplicateShip = (id: string) =>
    track(duplicateMissionShip(...template(), id));

  const sortShips = (sorting: string[]) => {
    const target = flight();
    return track(
      target
        ? sortFleetSquadronFlightShips(...target, { sorting })
        : sortMissionShips(...template(), { sorting }),
    );
  };

  const createSlot = (data: MissionSlotCreateInput) => {
    const target = flight();
    return track(
      target
        ? createFleetSquadronFlightSlot(...target, data)
        : createMissionSlot(data),
    );
  };

  const updateSlot = (id: string, data: MissionSlotUpdateInput) => {
    const target = flight();
    return track(
      target
        ? updateFleetSquadronFlightSlot(...target, id, data)
        : updateMissionSlot(id, data),
    );
  };

  const destroySlot = (id: string) => {
    const target = flight();
    return track(
      target
        ? destroyFleetSquadronFlightSlot(...target, id)
        : destroyMissionSlot(id),
    );
  };

  const sortSlots = (data: MissionSlotSortInput) => {
    const target = flight();
    return track(
      target
        ? sortFleetSquadronFlightSlots(...target, data)
        : sortMissionSlots(data),
    );
  };

  return {
    isPending,
    createShip,
    updateShip,
    destroyShip,
    duplicateShip,
    sortShips,
    createSlot,
    updateSlot,
    destroySlot,
    sortSlots,
  };
};
