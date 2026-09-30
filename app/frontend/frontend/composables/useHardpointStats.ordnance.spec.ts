import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentBomb,
  type ComponentMissile,
  type ComponentMissileRack,
  ComponentMissileTrackingSignalEnum,
  ComponentTypeEnum,
} from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

function ordnanceHardpoint(
  typeData: ComponentMissile | ComponentBomb | ComponentMissileRack,
  category: HardpointCategoryEnum = HardpointCategoryEnum.WEAPONS,
  type?: ComponentTypeEnum,
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "ordnance",
    category,
    component: { name: "Ordnance", type, typeData } as Hardpoint["component"],
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

  return Object.fromEntries(
    result!.value.map((stat) => [stat.label, stat.value]),
  );
}

describe("useHardpointStats for ordnance", () => {
  it("shows a missile's seeker, flight phases and fuse", () => {
    const stats = statsFor(
      ordnanceHardpoint({
        damagePerShot: { physical: 650 },
        trackingSignal: ComponentMissileTrackingSignalEnum.INFRARED,
        lockAngle: 60,
        signalResilienceMin: 1,
        signalResilienceMax: 1.7,
        boostPhaseDuration: 2,
        terminalPhaseTime: 1,
        dumbfire: true,
        armTime: 1.5,
        blastRadiusMin: 3,
        blastRadiusMax: 5,
      }),
    );

    expect(stats).toMatchObject({
      "labels.hardpoint.missiles.damage": "650",
      "labels.hardpoint.missiles.lockAngle": "60",
      "labels.hardpoint.missiles.signalResilience": "1 - 1.7",
      "labels.hardpoint.missiles.boostPhase": "2",
      "labels.hardpoint.missiles.dumbfire":
        "labels.hardpoint.missiles.dumbfireAllowed",
      "labels.hardpoint.missiles.armTime": "1.5",
      "labels.hardpoint.missiles.blastRadius": "3 - 5",
    });
  });

  it("shows a bomb, which carries a drop angle instead of a seeker", () => {
    const stats = statsFor(
      ordnanceHardpoint({
        damagePerShot: { physical: 22346, energy: 24356 },
        maxDropAngle: 90,
        blastRadiusMin: 100,
        blastRadiusMax: 100,
        armTime: 3,
      }),
    );

    expect(stats).toMatchObject({
      "labels.hardpoint.missiles.damage": "46702",
      "labels.hardpoint.weapons.damagePhysical": "22346",
      "labels.hardpoint.bombs.maxDropAngle": "90",
      "labels.hardpoint.missiles.blastRadius": "100",
      "labels.hardpoint.missiles.armTime": "3",
    });
    expect(stats).not.toHaveProperty("labels.hardpoint.missiles.lockTime");
  });

  it("reads a bomb by its type, even without a drop angle", () => {
    const stats = statsFor(
      ordnanceHardpoint(
        { damagePerShot: { physical: 100 }, armTime: 3 },
        HardpointCategoryEnum.WEAPONS,
        ComponentTypeEnum.BOMB,
      ),
    );

    expect(stats).toEqual({
      "labels.hardpoint.missiles.damage": "100",
      "labels.hardpoint.missiles.armTime": "3",
    });
  });

  it("shows a rack's launch delay in milliseconds", () => {
    const stats = statsFor(
      ordnanceHardpoint(
        { launchDelay: 0.125, igniteOnPylon: false },
        HardpointCategoryEnum.MISSILE_RACKS,
      ),
    );

    expect(stats).toEqual({
      "labels.hardpoint.missileRacks.launchDelay": "125",
      "labels.hardpoint.missileRacks.ignition":
        "labels.hardpoint.missileRacks.ignitesAfterRelease",
    });
  });
});
