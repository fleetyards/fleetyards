import { HardpointGroupEnum } from "@/services/fyApi";

// The hardpoint groups as the ship page stacks them, one list per column.
export const HARDPOINT_COLUMNS: HardpointGroupEnum[][] = [
  [
    HardpointGroupEnum.AVIONIC,
    HardpointGroupEnum.SYSTEM,
    HardpointGroupEnum.OTHER,
    HardpointGroupEnum.ORE_POD,
    HardpointGroupEnum.MINING,
    HardpointGroupEnum.SALVAGE,
    HardpointGroupEnum.SALVAGE_STORAGE,
    HardpointGroupEnum.MODULE,
    HardpointGroupEnum.EXTERNAL_FUEL_TANK,
  ],
  [HardpointGroupEnum.PROPULSION, HardpointGroupEnum.THRUSTER],
  [
    HardpointGroupEnum.WEAPON,
    HardpointGroupEnum.DEFENSE,
    HardpointGroupEnum.AUXILIARY,
  ],
];
