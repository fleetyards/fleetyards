import { describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import { useHardpointStats } from "./useHardpointStats";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

function hardpoint(
  category: HardpointCategoryEnum,
  typeData: Record<string, unknown>,
  hardpoints: Partial<Hardpoint>[] = [],
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "slot",
    category,
    component: { name: "Item", typeData } as unknown as Hardpoint["component"],
    hardpoints: hardpoints as Hardpoint[],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

// The composable injects page context, so it has to run inside an app.
function statsFor(slot: Hardpoint) {
  let result: ReturnType<typeof useHardpointStats> | undefined;
  createApp({ render: () => null }).runWithContext(() => {
    result = useHardpointStats(slot);
  });

  return result!.value;
}

const valueOf = (stats: { label: string; value: string }[], label: string) =>
  stats.find((stat) => stat.label === label)?.value;

describe("useHardpointStats rows", () => {
  it("shows a powered item's draw range and signatures on its row", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.COOLER, {
        coolingRate: 50,
        powerConsumption: 5,
        powerMinimumFraction: 0.4,
        signatureEm: 2480,
        signatureIr: 300,
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.powerConsumption")).toBe(
      "2 – 5 labels.hardpoint.powerSegments",
    );
    expect(valueOf(stats, "labels.hardpoint.signatureEm")).toBe("2480");
    expect(valueOf(stats, "labels.hardpoint.signatureIr")).toBe("300");
  });

  it("shows a shield's decay and absorption ranges", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.SHIELDGENERATOR, {
        maxHealth: 5000,
        maxRegen: 500,
        damagedRegenDelay: 4.55,
        downedRegenDelay: 9.09,
        decayRatio: 0.25,
        absorption: {
          physical: { min: 0.225, max: 0.45 },
          energy: { min: 1, max: 1 },
        },
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.shields.decay")).toBe("25%");
    expect(valueOf(stats, "labels.hardpoint.shields.absorption.physical")).toBe(
      "23 – 45%",
    );
    expect(valueOf(stats, "labels.hardpoint.shields.absorption.energy")).toBe(
      "100%",
    );
  });

  it("shows which signatures a radar sees passively and actively, and its ground-vehicle penalty", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.RADAR, {
        aimAssistRange: 632.5,
        aimAssistBuffer: 80,
        signatureDetection: {
          ir: { sensitivity: 0.75, passive: true, active: true },
          em: { sensitivity: 0.75, passive: true, active: true },
          cs: { sensitivity: 0.5, passive: false, active: true },
          rs: { sensitivity: 1, passive: true, active: true },
        },
        contactSensitivity: [
          { sensitivityAddition: -0.65, contactGroups: ["GroundVehicle"] },
          { sensitivityAddition: 0.25, contactGroups: ["Person", "Missile"] },
        ],
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.radar.passive")).toBe(
      "labels.hardpoint.radar.ir · labels.hardpoint.radar.em · labels.hardpoint.radar.rs",
    );
    expect(valueOf(stats, "labels.hardpoint.radar.aimAssistBuffer")).toBe(
      "80 m",
    );
    expect(
      valueOf(stats, "labels.hardpoint.radar.contactGroups.GroundVehicle"),
    ).toBe("-65%");
    expect(valueOf(stats, "Person · Missile")).toBe("25%");
  });

  it("still shows the penalty of a radar loaded before contact groups were parsed", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.RADAR, {
        aimAssistRange: 632.5,
        sensitivityModifiers: { sensitivityAddition: -0.5 },
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.radar.sensitivityModifier")).toBe(
      "-50%",
    );
  });

  it("shows a flex thruster's vectoring range and a VTOL-only thruster", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.RETRO_THRUSTERS, {
        thrustCapacity: 1_282_107,
        vtolOnly: true,
        gimbal: { minPitch: -90, maxPitch: 90, minYaw: -30, maxYaw: 30 },
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.thrusters.mode")).toBe(
      "labels.hardpoint.thrusters.vtolOnly",
    );
    expect(valueOf(stats, "labels.hardpoint.thrusters.vectorPitch")).toBe(
      "±90°",
    );
    expect(valueOf(stats, "labels.hardpoint.thrusters.vectorYaw")).toBe("±30°");
  });

  it("falls back to a mount's own ports when its ship slot lists none", () => {
    const slot = hardpoint(HardpointCategoryEnum.TURRET, { yawSpeed: 80 });
    slot.component!.hardpoints = [
      { category: HardpointCategoryEnum.WEAPON_MOUNTS, maxSize: 3 },
      { category: HardpointCategoryEnum.WEAPON_MOUNTS, maxSize: 3 },
    ] as Hardpoint[];

    expect(valueOf(statsFor(slot), "labels.hardpoint.turrets.gunPorts")).toBe(
      "2 × S3",
    );
  });

  it("falls back to a mount's own ports when its ship slot lists only a seat", () => {
    const slot = hardpoint(HardpointCategoryEnum.TURRET, { yawSpeed: 80 }, [
      { category: HardpointCategoryEnum.SEAT, maxSize: 1 },
    ]);
    slot.component!.hardpoints = [
      { category: HardpointCategoryEnum.WEAPON_MOUNTS, maxSize: 4 },
      { category: HardpointCategoryEnum.WEAPON_MOUNTS, maxSize: 4 },
    ] as Hardpoint[];

    expect(valueOf(statsFor(slot), "labels.hardpoint.turrets.gunPorts")).toBe(
      "2 × S4",
    );
  });

  it("gives a thruster its signatures but no power segments", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.MAIN_THRUSTERS, {
        thrustCapacity: 1_000_000,
        powerConsumption: 2,
        signatureIr: 150,
      }),
    );

    expect(valueOf(stats, "labels.hardpoint.powerConsumption")).toBeUndefined();
    expect(valueOf(stats, "labels.hardpoint.signatureIr")).toBe("150");
  });

  it("counts a mount's gun ports by size, leaving out its other slots", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.TURRET, { yawSpeed: 80 }, [
        { category: HardpointCategoryEnum.WEAPON_MOUNTS, maxSize: 3 },
        { category: HardpointCategoryEnum.WEAPON_MOUNTS, maxSize: 3 },
        { category: HardpointCategoryEnum.WEAPONS, maxSize: 4 },
        { category: HardpointCategoryEnum.SEAT, maxSize: 1 },
      ]),
    );

    expect(valueOf(stats, "labels.hardpoint.turrets.gunPorts")).toBe(
      "1 × S4 + 2 × S3",
    );
  });

  it("shows an EMP's burst rather than gun figures", () => {
    const stats = statsFor(
      hardpoint(HardpointCategoryEnum.WEAPONS, {
        empRadius: 4500,
        minEmpRadius: 500,
        distortionDamage: 6000,
        chargeTime: 20,
        cooldownTime: 7.5,
      }),
    );

    expect(stats[0]).toMatchObject({
      label: "labels.hardpoint.emp.distortionDamage",
      primary: true,
    });
    expect(valueOf(stats, "labels.hardpoint.emp.radius")).toBe("500 – 4500 m");
    expect(valueOf(stats, "labels.hardpoint.emp.cooldownTime")).toBe("7.5");
  });
});
