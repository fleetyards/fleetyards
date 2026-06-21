// Suggestion list for the Mission.scenario free-text field.
// Used to populate a <datalist> for autocomplete; users can type custom values.

export const MISSION_SCENARIO_SUGGESTIONS: readonly string[] = [
  // Time-limited / dynamic events
  "Xenothreat",
  "Blockade Runner",
  "Jumptown",
  "Save Stanton",
  "Siege of Orison",
  "Daymar Rally",
  "Idris Disabled",
  "Pirate Swarm Wave",
  "Hostile Takeover",
  "Defend Outpost",
  "Hangar Defense",
  // Recurring fixed encounters
  "Vanduul Swarm",
  "Master Modes Free Fly",
  "Investigate Drug Lab",
  "Bounty Hunter Beacon",
  "Bounty: ERT",
  "Bounty: VHRT",
  "Bounty: HRT",
  "Reclaim Cargo",
  "Recover Black Box",
] as const;

export const useMissionScenarios = () => {
  return { suggestions: MISSION_SCENARIO_SUGGESTIONS };
};
