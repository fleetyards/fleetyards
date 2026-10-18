import { THRUSTER_CATEGORIES } from "@/frontend/composables/useHardpointStats";
import {
  type ComponentThruster,
  type Hardpoint,
  HardpointCategoryEnum,
} from "@/services/fyApi";

export interface FuelDraw {
  // µSCU per second, every thruster at full thrust.
  all: number;
  // µSCU per second, the main thrusters alone: burning forward.
  main: number;
}

const flatten = (hardpoints: Hardpoint[]): Hardpoint[] =>
  hardpoints.flatMap((hardpoint) => [
    hardpoint,
    ...flatten(hardpoint.hardpoints ?? []),
  ]);

/**
 * What a ship's thrusters draw from its fuel network at full thrust: each
 * one's draw per 10 kN times its thrust, as erkul works it out. A thruster
 * without the draw -- from a tree parsed before it was read -- adds nothing.
 */
export const fuelDraw = (hardpoints: Hardpoint[]): FuelDraw =>
  flatten(hardpoints).reduce(
    (draw, hardpoint) => {
      if (
        !hardpoint.category ||
        !THRUSTER_CATEGORIES.includes(hardpoint.category)
      ) {
        return draw;
      }

      const thruster = hardpoint.component?.typeData as
        ComponentThruster | undefined;
      if (!thruster?.thrustCapacity || !thruster.fuelBurnScuPer10KNewton) {
        return draw;
      }

      const microScu =
        (thruster.thrustCapacity / 10_000) *
        thruster.fuelBurnScuPer10KNewton *
        1_000_000;

      return {
        all: draw.all + microScu,
        main:
          draw.main +
          (hardpoint.category === HardpointCategoryEnum.MAIN_THRUSTERS
            ? microScu
            : 0),
      };
    },
    { all: 0, main: 0 },
  );

// Seconds a tank of `scu` lasts at a draw of `microScuPerSecond`.
export const fuelEndurance = (scu: number, microScuPerSecond: number) =>
  microScuPerSecond > 0 ? scu / (microScuPerSecond / 1_000_000) : undefined;
