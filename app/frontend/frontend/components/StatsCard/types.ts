export interface StatsCardBadge {
  key: string;
  label: string;
  value: string;
  unit?: string;
}

// The types a hover card can describe, named as the API names them so a
// reference's `type` selects its icon and wording directly.
export type StatsCardKind =
  | "Component"
  | "Equipment"
  | "Commodity"
  | "Model"
  | "Blueprint"
  | "GameMission"
  | "FleetContract"
  | "FleetEvent"
  | "User";

export type StatsCardStatusTone = "success" | "warning" | "danger" | "neutral";

export interface StatsCardStatus {
  label: string;
  tone: StatsCardStatusTone;
}
