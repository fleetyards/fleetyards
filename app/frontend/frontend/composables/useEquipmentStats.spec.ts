import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { EquipmentTypeEnum, type Equipment } from "@/services/fyApi";
import { useEquipmentStats } from "./useEquipmentStats";

const equipment = (attrs: Partial<Equipment>): Equipment =>
  ({
    id: "1",
    name: "Test Item",
    slug: "test-item",
    retired: false,
    availability: { boughtAt: [], soldAt: [] },
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Equipment;

describe("useEquipmentStats", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("leads armour with damage reduction and temperature rating", () => {
    const stats = useEquipmentStats(
      equipment({
        equipmentType: EquipmentTypeEnum.ARMOR,
        damageReduction: 30,
        temperatureRating: "-61 / 91 °C",
        radiationProtection: 26400,
      }),
    );

    const primary = stats.value.filter((stat) => stat.primary);

    expect(primary.map((stat) => stat.label)).toEqual([
      "Damage Reduction",
      "Temperature Rating",
    ]);
    expect(primary[0].value).toContain("30");
    expect(primary[1].value).toBe("-61 / 91 °C");
    expect(stats.value.map((stat) => stat.label)).toContain(
      "Radiation Protection",
    );
  });

  it("leads a weapon with rate of fire and range, and names storage a magazine", () => {
    const stats = useEquipmentStats(
      equipment({
        equipmentType: EquipmentTypeEnum.WEAPON,
        rateOfFire: 1000,
        range: 35,
        storage: 1000,
        weaponClassLabel: "Ballistic",
      }),
    );

    expect(
      stats.value.filter((stat) => stat.primary).map((stat) => stat.label),
    ).toEqual(["Rate of Fire", "Effective Range"]);
    expect(stats.value.map((stat) => stat.label)).toEqual(
      expect.arrayContaining(["Magazine Size", "Weapon Class"]),
    );
    expect(stats.value.map((stat) => stat.label)).not.toContain(
      "Carrying Capacity",
    );
  });

  // Most items carry fewer than half of their type's list, and a card of
  // "N/A" rows reads as a failed load.
  it("leaves out every figure the item does not carry", () => {
    const stats = useEquipmentStats(
      equipment({ equipmentType: EquipmentTypeEnum.CLOTHING }),
    );

    expect(stats.value).toEqual([]);
  });

  it("keeps a figure recorded as zero", () => {
    const stats = useEquipmentStats(
      equipment({ equipmentType: EquipmentTypeEnum.ARMOR, damageReduction: 0 }),
    );

    expect(stats.value).toEqual([
      { label: "Damage Reduction", value: "0%", primary: true },
    ]);
  });

  // As SCU a jacket is 0.0087, which the stat formatter rounds to nothing.
  it("states volume in µSCU", () => {
    const stats = useEquipmentStats(
      equipment({ equipmentType: EquipmentTypeEnum.CLOTHING, volume: 0.0087 }),
    );

    const volume = stats.value.find((stat) => stat.label === "Volume");

    expect(volume?.value).toMatch(/8.?700 µSCU/);
  });

  it("falls back to volume alone for a type without a vocabulary", () => {
    const stats = useEquipmentStats(
      equipment({
        equipmentType: EquipmentTypeEnum.MEDICAL,
        volume: 0.001,
        damageReduction: 10,
      }),
    );

    expect(stats.value.map((stat) => stat.label)).toEqual(["Volume"]);
  });
});
