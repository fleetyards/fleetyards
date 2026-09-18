import radarIconUrl from "@/images/hardpoints/radar.svg";
import computersIconUrl from "@/images/hardpoints/computers.svg";
import powerPlantsIconUrl from "@/images/hardpoints/power_plants.svg";
import coolersIconUrl from "@/images/hardpoints/coolers.svg";
import shieldGeneratorsIconUrl from "@/images/hardpoints/shield_generators.svg";
import fuelIntakesIconUrl from "@/images/hardpoints/fuel_intakes.svg";
import fuelTanksIconUrl from "@/images/hardpoints/fuel_tanks.svg";
import quantumDrivesIconUrl from "@/images/hardpoints/quantum_drives.svg";
import jumpModulesIconUrl from "@/images/hardpoints/jump_modules.svg";
import quantumFuelTanksIconUrl from "@/images/hardpoints/quantum_fuel_tanks.svg";
import mainThrustersIconUrl from "@/images/hardpoints/main_thrusters.svg";
import vtolThrustersIconUrl from "@/images/hardpoints/vtol_thrusters.svg";
import retroThrustersIconUrl from "@/images/hardpoints/retro_thrusters.svg";
import maneuveringThrustersIconUrl from "@/images/hardpoints/maneuvering_thrusters.svg";
import weaponsIconUrl from "@/images/hardpoints/weapons.svg";
import turretsIconUrl from "@/images/hardpoints/turrets.svg";
import missilesIconUrl from "@/images/hardpoints/missiles.svg";
import utilityItemsIconUrl from "@/images/hardpoints/utility_items.svg";
import qedIconUrl from "@/images/hardpoints/qed.svg";
import empIconUrl from "@/images/hardpoints/emp.svg";

// The drawn set. Keyed by the category string itself, which a component and a
// hardpoint slot share for everything below -- the exception is thrusters, and
// it is handled in `categoryIcon`.
export const categorySvgIcons = {
  radar: radarIconUrl,
  computers: computersIconUrl,
  powerplant: powerPlantsIconUrl,
  cooler: coolersIconUrl,
  shieldgenerator: shieldGeneratorsIconUrl,
  fuel_intakes: fuelIntakesIconUrl,
  fueltanks: fuelTanksIconUrl,
  external_fuel_tanks: fuelTanksIconUrl,
  refuel_boom: fuelIntakesIconUrl,
  quantumdrive: quantumDrivesIconUrl,
  jump_modules: jumpModulesIconUrl,
  jumpdrive: jumpModulesIconUrl,
  quantum_fuel_tanks: quantumFuelTanksIconUrl,
  main_thrusters: mainThrustersIconUrl,
  vtol_thrusters: vtolThrustersIconUrl,
  retro_thrusters: retroThrustersIconUrl,
  maneuvering_thrusters: maneuveringThrustersIconUrl,
  weapons: weaponsIconUrl,
  weapon_mounts: weaponsIconUrl,
  turret: turretsIconUrl,
  missiles: missilesIconUrl,
  missile_racks: missilesIconUrl,
  utility: utilityItemsIconUrl,
  utility_items: utilityItemsIconUrl,
  quantumenforcementdevice: qedIconUrl,
  emp: empIconUrl,
} as const;

// The categories the drawn set never got, carried as Font Awesome glyphs the
// hardpoint list already renders.
//
// The second block is what the components catalogue turned up: a hardpoint list
// never shows these, so nothing had needed them before, and between them they
// were 2,049 of the 4,254 listed components -- 48% of the catalogue rendering
// with an empty icon slot. Paints and doors alone are 1,761 of that.
export const categoryFaIcons: Record<string, string> = {
  armor: "fa-duotone fa-shield-halved",
  countermeasures: "fa-duotone fa-shield-quartered",
  lifesupport: "fa-duotone fa-heart-pulse",
  module: "fa-duotone fa-puzzle",
  seat: "fa-duotone fa-person-seat-reclined",
  cargogrid: "fa-duotone fa-thin fa-cubes",
  salvagefillerstation: "fa-duotone fa-bin-recycle",
  relay: "fa-duotone fa-transformer-bolt",

  paints: "fa-duotone fa-palette",
  doors: "fa-duotone fa-door-open",
  // Ship subsystem controllers rather than anything a player holds -- the
  // entries are named after what they drive, "SHIELDS" and the like.
  controller: "fa-duotone fa-sliders",
  bombcompartments: "fa-duotone fa-bomb",
  selfdestruct: "fa-duotone fa-explosion",
  // The loader's fallback when the game files name no category, so the glyph
  // says exactly that rather than guessing at one.
  unknown: "fa-duotone fa-circle-question",
};

// A component's own category is one word where a hardpoint slot names the four
// places a thruster sits, so `thrusters` has no icon of its own. The main
// thruster's stands for the group, as it does in the hardpoint list.
const ALIASES: Record<string, keyof typeof categorySvgIcons> = {
  thrusters: "main_thrusters",
};

export type CategoryIcon =
  { kind: "svg"; src: string } | { kind: "fa"; className: string };

export const categoryIcon = (
  category?: string | null,
): CategoryIcon | undefined => {
  if (!category) return undefined;

  const key = ALIASES[category] ?? (category as keyof typeof categorySvgIcons);
  const src = categorySvgIcons[key];
  if (src) return { kind: "svg", src };

  const className = categoryFaIcons[category];
  if (className) return { kind: "fa", className };

  return undefined;
};
