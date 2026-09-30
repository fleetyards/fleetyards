import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentTurret,
  ComponentTurretControlEnum,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

function mountHardpoint(
  typeData: ComponentTurret,
  category: HardpointCategoryEnum = HardpointCategoryEnum.TURRET,
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "mount",
    category,
    component: { name: "Mount", typeData } as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

// The composable injects page context, so it has to run inside an app.
function statsFor(hardpoint: Hardpoint) {
  let result: ReturnType<typeof useHardpointStats> | undefined;
  createApp({ render: () => null }).runWithContext(() => {
    result = useHardpointStats(hardpoint);
  });

  return result!.value;
}

describe("useHardpointStats for mounts", () => {
  it("shows one turn rate when both axes turn alike", () => {
    const stats = statsFor(
      mountHardpoint(
        { yawSpeed: 80, pitchSpeed: 80 },
        HardpointCategoryEnum.WEAPON_MOUNTS,
      ),
    );

    expect(stats).toEqual([
      {
        label: "labels.hardpoint.turrets.turnRate",
        value: "80 °/s",
        primary: true,
      },
    ]);
  });

  it("shows yaw and pitch when they differ, and who controls the mount", () => {
    const stats = statsFor(
      mountHardpoint({
        yawSpeed: 290,
        pitchSpeed: 225,
        control: ComponentTurretControlEnum.PDS,
      }),
    );

    expect(stats.map((stat) => stat.value)).toEqual([
      "290 / 225 °/s",
      "labels.combat.controlGroups.pds",
    ]);
  });

  it("shows nothing for a mount without parsed joints", () => {
    expect(statsFor(mountHardpoint({ signatureEm: 0 }))).toEqual([]);
  });
});
