import type {
  HangarPlanAcquisition,
  HangarPlanCandidate,
  HangarPlanModel,
  HangarPlanSlot,
  HangarPlanSlotStart,
} from "@/services/fyApi";

export type HangarFlowDecision = "keep" | "melt" | "change" | "pending";

export const hangarFlowDecisionIcons: Record<HangarFlowDecision, string> = {
  keep: "fa-light fa-check",
  melt: "fa-light fa-fire",
  change: "fa-light fa-arrows-rotate",
  pending: "fa-light fa-rotate-left",
};

// Where a route starts, for picking where it ends: a hangar ship, a route
// already planned, or both.
export type HangarFlowEnd = {
  startName: string;
  startModel?: HangarPlanModel;
  vehicleId?: string;
  acquisition?: HangarPlanAcquisition;
  slot?: HangarPlanSlot;
};

// What a start is picked for: a slot, its ship once it has chosen one, and the
// route that already reaches it or the start the slot holds until it has one.
export type HangarFlowStart = {
  slot: HangarPlanSlot;
  candidate?: HangarPlanCandidate;
  acquisition?: HangarPlanAcquisition | HangarPlanSlotStart;
};

// Which side of a row the ship panel shows: a slot still choosing its ship
// opens its own view where a route would have an end.
export type HangarFlowTab = "start" | "route" | "end" | "slot";

// A row as the ship panel opens it: the side asked for, and every other side
// the row has, offered as tabs.
export type HangarFlowTarget = {
  key: string;
  tab: HangarFlowTab;
  start?: HangarFlowStart;
  end?: HangarFlowEnd;
  route?: {
    candidate: HangarPlanCandidate;
    acquisition: HangarPlanAcquisition;
  };
  slot?: HangarPlanSlot;
};
