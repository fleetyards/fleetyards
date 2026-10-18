import { describe, expect, it, vi } from "vitest";
import type { Hardpoint, LoadoutSlot } from "@/services/fyApi";
import { lowerIsBetter, useComponentFitting } from "./useComponentFitting";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

describe("lowerIsBetter", () => {
  it("reads signatures, times, cooldowns, draws and fuel burn as better smaller", () => {
    [
      "signatureEm",
      "signatureIr",
      "powerConsumption",
      "quantumDrives.spoolUpTime",
      "quantumDrives.fuelConsumption",
      "controllers.reconfigurationCooldown",
      "thrusters.fuelBurn",
      "missiles.lockTime",
      "weapons.heatPerShot",
    ].forEach((key) => expect(lowerIsBetter(key), key).toBe(true));
  });

  it("reads output, damage and speed as better larger", () => {
    [
      "shields.hp",
      "powerPlants.output",
      "weapons.burstDps",
      "quantumDrives.speed",
      "missiles.lockRange",
    ].forEach((key) => expect(lowerIsBetter(key), key).toBe(false));
  });
});

describe("graft", () => {
  const port = (
    name: string,
    attributes: Partial<LoadoutSlot> = {},
  ): LoadoutSlot =>
    ({
      name,
      hardpointId: `port-${name}`,
      category: "unknown",
      types: [],
      editable: true,
      slots: [],
      ...attributes,
    }) as LoadoutSlot;

  it("leaves out a part's empty ports nothing is fitted to, as the editor does", () => {
    const fitting = useComponentFitting();
    const hull = port("hardpoint_gun_nose", {
      category: "weapon_mounts",
      types: ["Turret"],
      stock: { id: "gimbal", name: "Gimbal" },
      slots: [
        port("hardpoint_class_2", {
          category: "weapons",
          types: ["WeaponGun"],
          stock: { id: "gun", name: "Gun" },
          slots: [port("bar1", { types: ["WeaponAttachment"] })],
        }),
      ],
    } as Partial<LoadoutSlot>);
    fitting.learn([hull]);

    const [nose] = fitting.graft(
      [{ id: "hp-nose", name: "hardpoint_gun_nose" } as Hardpoint],
      fitting.resolve([hull], {}),
    );

    expect(nose.hardpoints?.map((hp) => hp.name)).toEqual([
      "hardpoint_class_2",
    ]);
    expect(nose.hardpoints?.[0].hardpoints).toEqual([]);
  });
});
