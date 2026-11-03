import { describe, expect, it, vi } from "vitest";
import { EquipmentTypeEnum, type Equipment } from "@/services/fyApi";
import { useEquipmentSections } from "./equipment";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
    toUEC: (value: number) => String(value),
    toDollar: (value: number) => String(value),
  }),
}));

const rifle = (slug: string, fields: Partial<Equipment>) =>
  ({
    slug,
    name: slug,
    equipmentType: EquipmentTypeEnum.WEAPON,
    ...fields,
  }) as Equipment;

describe("useEquipmentSections", () => {
  it("compares the figures a weapon's page leads with", () => {
    const { sections } = useEquipmentSections([
      rifle("p4", { rateOfFire: 550, range: 50, storage: 30 }),
      rifle("karna", { rateOfFire: 300, range: 60, storage: 35 }),
    ]);

    const metrics = sections.value.find((section) => section.id === "metrics");
    const range = metrics?.rows.find((row) => row.key === "stat-range");
    const rateOfFire = metrics?.rows.find(
      (row) => row.key === "stat-rateOfFire",
    );

    expect(range?.kind === "value" && range.direction).toBe("higher");
    expect(
      range?.kind === "value" && range.cells.map((cell) => cell.raw),
    ).toEqual([50, 60]);
    // A faster gun is not a better one on its own.
    expect(rateOfFire?.kind === "value" && rateOfFire.direction).toBe(
      undefined,
    );
  });

  it("drops the figures section when nothing is recorded", () => {
    const { sections } = useEquipmentSections([
      rifle("a", { manufacturer: { name: "Behring" } } as Partial<Equipment>),
    ]);

    expect(sections.value.map((section) => section.id)).toEqual(["identity"]);
  });
});
