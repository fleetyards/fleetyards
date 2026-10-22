import { type VehiclePlaqueStyleEnum } from "@/services/fyApi";
import { type PlaqueMaker } from "./makers";

// Brass is free; every other style is a supporter perk.
export const FREE_PLAQUE_STYLE: VehiclePlaqueStyleEnum = "brass";

// A supporter whose ship has a maker style of its own starts on it: it is the
// plaque made for that ship.
export const defaultPlaqueStyle = (
  isSupporter: boolean,
  maker?: PlaqueMaker,
): VehiclePlaqueStyleEnum =>
  isSupporter && maker ? "manufacturer" : FREE_PLAQUE_STYLE;
