import { describe, expect, it, vi } from "vitest";
import type { Component } from "@/services/fyApi";
import type { CompareTableRow } from "@/frontend/components/Compare/types";
import { useComponentSections } from "./component";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    tExists: () => false,
    toNumber: (value: number) => String(value),
    toUEC: (value: number) => String(value),
    toDollar: (value: number) => String(value),
  }),
}));

const shield = (
  slug: string,
  typeData: Record<string, unknown>,
  extra: Partial<Component> = {},
) =>
  ({
    slug,
    name: slug,
    category: "shieldgenerator",
    typeData,
    media: {},
    ...extra,
  }) as unknown as Component;

const rowOf = (
  sections: { id: string; rows: CompareTableRow[] }[],
  sectionId: string,
  key: string,
) =>
  sections
    .find((section) => section.id === sectionId)
    ?.rows.find((row) => row.key === key);

describe("useComponentSections", () => {
  it("lines up each figure across the compared items, with its direction", () => {
    const { sections } = useComponentSections([
      shield("small", { maxHealth: 1000, maxRegen: 100 }),
      shield("large", { maxHealth: 4000, maxRegen: 200 }),
    ]);

    const hp = rowOf(sections.value, "metrics", "stat-shields.hp");
    const regen = rowOf(sections.value, "metrics", "stat-shields.regenTime");

    expect(hp?.kind === "value" && hp.direction).toBe("higher");
    expect(
      hp?.kind === "value" && hp.cells.map((cell) => [cell.key, cell.raw]),
    ).toEqual([
      ["small", 1000],
      ["large", 4000],
    ]);
    expect(regen?.kind === "value" && regen.direction).toBe("lower");
  });

  it("leaves a cell empty for an item without the figure", () => {
    const { sections } = useComponentSections([
      shield("plain", { maxHealth: 1000 }),
      shield("delayed", { maxHealth: 1000, downedRegenDelay: 4.5 }),
    ]);

    const delay = rowOf(
      sections.value,
      "metrics",
      "stat-shields.downedRegenDelay",
    );

    const values =
      delay?.kind === "value" ? delay.cells.map((cell) => cell.value) : [];

    expect(values[0]).toBeUndefined();
    expect(values[1]).toBeTruthy();
  });

  it("drops a section none of the items has data for", () => {
    const { sections } = useComponentSections([
      shield("a", { maxHealth: 1000 }),
      shield("b", { maxHealth: 2000 }),
    ]);

    expect(sections.value.map((section) => section.id)).toEqual([
      "identity",
      "metrics",
    ]);
  });

  it("shows only the damage types some item takes differently", () => {
    const { sections } = useComponentSections([
      shield("a", {}, {
        durability: { health: 500, resistances: { physical: 1, energy: 0.5 } },
      } as Partial<Component>),
      shield("b", {}, {
        durability: { health: 800, resistances: { physical: 1, energy: 1 } },
      } as Partial<Component>),
    ]);

    const durability = sections.value.find(
      (section) => section.id === "durability",
    );

    expect(durability?.rows.map((row) => row.key)).toEqual([
      "health",
      "damage-energy",
    ]);
  });
});
