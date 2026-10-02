import { LocationKindEnum } from "@/services/fyApi";

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
