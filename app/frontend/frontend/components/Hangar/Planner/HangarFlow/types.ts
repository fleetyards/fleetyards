export type HangarFlowDecision =
  "keep" | "upgrade" | "melt" | "change" | "pending";

export const hangarFlowDecisionIcons: Record<HangarFlowDecision, string> = {
  keep: "fa-light fa-check",
  upgrade: "fa-light fa-arrow-up-right",
  melt: "fa-light fa-fire",
  change: "fa-light fa-arrows-rotate",
  pending: "fa-light fa-rotate-left",
};
