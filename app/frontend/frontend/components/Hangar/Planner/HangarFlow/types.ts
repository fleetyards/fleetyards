import type {
  HangarPlanAcquisition,
  HangarPlanCandidate,
  HangarPlanModel,
  HangarPlanSlot,
} from "@/services/fyApi";

export type HangarFlowDecision = "melt" | "change" | "pending";

export const hangarFlowDecisionIcons: Record<HangarFlowDecision, string> = {
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
// route that already reaches it.
export type HangarFlowStart = {
  slot: HangarPlanSlot;
  candidate?: HangarPlanCandidate;
  acquisition?: HangarPlanAcquisition;
};
