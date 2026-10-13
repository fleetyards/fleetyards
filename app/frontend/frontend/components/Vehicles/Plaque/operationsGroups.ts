import { NullableVehicleOperationsGroupEnum } from "@/services/fyApi";

type OperationsGroup = NonNullable<NullableVehicleOperationsGroupEnum>;

type OperationsGroupDetails = {
  // The full name, which the form offers.
  name: string;
  // What the plaque prints over the column: short enough for one line.
  heading: string;
  alignment: "lawful" | "neutral" | "outlaw";
};

// Groups from the game's lore. Their names are proper nouns in every language,
// as "UEE" is on Cloud Imperium's own plaque, so they are not translated.
export const OPERATIONS_GROUPS: Record<
  OperationsGroup,
  OperationsGroupDetails
> = {
  [NullableVehicleOperationsGroupEnum.UEE]: {
    name: "United Empire of Earth",
    heading: "UEE Operations",
    alignment: "lawful",
  },
  [NullableVehicleOperationsGroupEnum.MERCENARY_GUILD]: {
    name: "Mercenary Guild",
    heading: "Mercenary Guild",
    alignment: "neutral",
  },
  [NullableVehicleOperationsGroupEnum.ITG]: {
    name: "Interstellar Transport Guild",
    heading: "ITG Operations",
    alignment: "neutral",
  },
  [NullableVehicleOperationsGroupEnum.CFP]: {
    name: "Citizens for Prosperity",
    heading: "CFP Operations",
    alignment: "neutral",
  },
  [NullableVehicleOperationsGroupEnum.SHUBIN]: {
    name: "Shubin Interstellar",
    heading: "Shubin Interstellar",
    alignment: "neutral",
  },
  [NullableVehicleOperationsGroupEnum.NINE_TAILS]: {
    name: "Nine Tails",
    heading: "Nine Tails",
    alignment: "outlaw",
  },
  [NullableVehicleOperationsGroupEnum.HEADHUNTERS]: {
    name: "Headhunters",
    heading: "Headhunters",
    alignment: "outlaw",
  },
  [NullableVehicleOperationsGroupEnum.XENOTHREAT]: {
    name: "XenoThreat",
    heading: "XenoThreat",
    alignment: "outlaw",
  },
  [NullableVehicleOperationsGroupEnum.ROUGH_AND_READY]: {
    name: "Rough & Ready",
    heading: "Rough & Ready",
    alignment: "outlaw",
  },
};

export const DEFAULT_OPERATIONS_GROUP: OperationsGroup =
  NullableVehicleOperationsGroupEnum.UEE;
