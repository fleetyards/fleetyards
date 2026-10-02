import { LocationKindEnum } from "@/services/fyApi";

// The glyph each kind is drawn with, in the strip, the counts and the rows.
export const LOCATION_KIND_ICONS: Record<LocationKindEnum, string> = {
  [LocationKindEnum.SYSTEM]: "fa-duotone fa-solar-system",
  [LocationKindEnum.STAR]: "fa-duotone fa-sun",
  [LocationKindEnum.PLANET]: "fa-duotone fa-planet-ringed",
  [LocationKindEnum.MOON]: "fa-duotone fa-moon",
  [LocationKindEnum.CITY]: "fa-duotone fa-city",
  [LocationKindEnum.STATION]: "fa-duotone fa-satellite",
  [LocationKindEnum.OUTPOST]: "fa-duotone fa-house-flag",
  [LocationKindEnum.ASTEROID]: "fa-duotone fa-meteor",
  [LocationKindEnum.ANOMALY]: "fa-duotone fa-sparkles",
  [LocationKindEnum.JUMP_POINT]: "fa-duotone fa-circle-nodes",
  [LocationKindEnum.POINT_OF_INTEREST]: "fa-duotone fa-location-dot",
  [LocationKindEnum.NAV_POINT]: "fa-duotone fa-location-crosshairs",
  [LocationKindEnum.OTHER]: "fa-duotone fa-circle-question",
};

// Where a reader expects to find a place: bodies first, then what is on or
// around them, then what is merely there.
export const LOCATION_KIND_ORDER: LocationKindEnum[] = [
  LocationKindEnum.SYSTEM,
  LocationKindEnum.STAR,
  LocationKindEnum.PLANET,
  LocationKindEnum.MOON,
  LocationKindEnum.CITY,
  LocationKindEnum.STATION,
  LocationKindEnum.OUTPOST,
  LocationKindEnum.JUMP_POINT,
  LocationKindEnum.POINT_OF_INTEREST,
  LocationKindEnum.ASTEROID,
  LocationKindEnum.ANOMALY,
  LocationKindEnum.NAV_POINT,
  LocationKindEnum.OTHER,
];
