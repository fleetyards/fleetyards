import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type ComponentMissileController,
  type ComponentShieldController,
  type ComponentShieldFaceTypeEnum,
  type Hardpoint,
} from "@/services/fyApi";

export type ControllerStats = {
  shieldFaceType?: ComponentShieldFaceTypeEnum;
  reconfigurationCooldown?: number;
  maxArmedMissiles?: number;
  launchCooldown?: number;
};

function collect(hardpoints: Hardpoint[] | undefined, stats: ControllerStats) {
  for (const hardpoint of hardpoints || []) {
    if (hardpoint.category === HardpointCategoryEnum.CONTROLLER) {
      const typeData = hardpoint.component?.typeData as
        (ComponentShieldController & ComponentMissileController) | undefined;

      if (typeData?.faceType && !stats.shieldFaceType) {
        stats.shieldFaceType = typeData.faceType;
        stats.reconfigurationCooldown = typeData.reconfigurationCooldown;
      }
      if (typeData?.maxArmedMissiles && !stats.maxArmedMissiles) {
        stats.maxArmedMissiles = typeData.maxArmedMissiles;
        stats.launchCooldown = typeData.launchCooldown;
      }
    }

    collect(hardpoint.hardpoints, stats);
  }
}

// What the ship's shield and missile controllers decide for the whole ship:
// whether its shield is one bubble or four faces, and how many missiles it
// can hold armed at once. A ship carries one of each.
export function computeControllerStats(
  hardpoints: Hardpoint[] | undefined,
): ControllerStats {
  const stats: ControllerStats = {};

  collect(hardpoints, stats);

  return stats;
}

export function useControllerStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
) {
  return computed(() => computeControllerStats(toValue(hardpoints)));
}
