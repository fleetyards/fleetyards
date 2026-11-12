import { type MyFleetSummary } from "@/services/fyApi";

// The fleet the dashboard is about: the one the pilot marked primary, else the
// first they joined.
export const primaryFleet = (fleets: MyFleetSummary[]) =>
  fleets.find((fleet) => fleet.primary) || fleets[0];
