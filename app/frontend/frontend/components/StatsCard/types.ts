export interface StatsCardBadge {
  key: string;
  label: string;
  value: string;
  unit?: string;
  // A value too long for a third of the card -- a jurisdiction's name -- gets
  // a row to itself. Only on the last badge.
  wide?: boolean;
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
  | "Location"
  | "FleetContract"
  | "FleetEvent"
  | "User"
  | "FleetMember";

export type StatsCardStatusTone = "success" | "warning" | "danger" | "neutral";

export interface StatsCardStatus {
  label: string;
  tone: StatsCardStatusTone;
}
