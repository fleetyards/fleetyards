import { describe, expect, it, vi } from "vitest";
import {
  ComponentShieldFaceTypeEnum,
  HardpointCategoryEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import type { CompareTableRow } from "@/frontend/components/Compare/types";
import { useLoadoutSections } from "./loadout";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
    toUEC: (value: number) => String(value),
    toDollar: (value: number) => String(value),
  }),
}));

function hardpoint(
  category: HardpointCategoryEnum,
  typeData: Record<string, unknown>,
): Hardpoint {
  return {
    id: Math.random().toString(),
    name: "port",
    category,
    component: { name: "Part", typeData } as unknown as Hardpoint["component"],
    hardpoints: [],
    createdAt: "",
    updatedAt: "",
  } as Hardpoint;
}

const model = (slug: string) =>
  ({ slug, name: slug, metrics: {} }) as unknown as Model;

const cellsOf = (rows: CompareTableRow[] | undefined, key: string) => {
  const row = rows?.find((entry) => entry.key === key);
  return row && "cells" in row
    ? row.cells.map((cell) => ("value" in cell ? cell.value : undefined))
    : undefined;
};

describe("useLoadoutSections controller rows", () => {
  const hardpoints: Record<string, Hardpoint[]> = {
    quadrant: [
      hardpoint(HardpointCategoryEnum.SHIELDGENERATOR, {
        maxHealth: 1000,
        maxRegen: 50,
      }),
      hardpoint(HardpointCategoryEnum.CONTROLLER, {
        faceType: ComponentShieldFaceTypeEnum.QUADRANT,
        reconfigurationCooldown: 2.5,
      }),
      hardpoint(HardpointCategoryEnum.CONTROLLER, {
        maxArmedMissiles: 8,
        launchCooldown: 0,
      }),
      hardpoint(HardpointCategoryEnum.WEAPONS, {
        trackingSignal: "infrared",
        damagePerShot: { physical: 2000 },
      }),
    ],
    bubble: [
      hardpoint(HardpointCategoryEnum.SHIELDGENERATOR, {
        maxHealth: 800,
        maxRegen: 40,
      }),
      hardpoint(HardpointCategoryEnum.CONTROLLER, {
        faceType: ComponentShieldFaceTypeEnum.BUBBLE,
        reconfigurationCooldown: 2.5,
      }),
    ],
  };

  const { combat, defense } = useLoadoutSections(
    [model("quadrant"), model("bubble")],
    (entry) => hardpoints[entry.slug],
  );

  it("compares armed-missile capacity and launch cooldown", () => {
    expect(cellsOf(combat.value?.rows, "armed-missiles")).toEqual([
      "8",
      undefined,
    ]);
    expect(cellsOf(combat.value?.rows, "launch-cooldown")).toEqual([
      "0",
      undefined,
    ]);
  });

  it("shows no gun figures for a missile-only ship", () => {
    expect(cellsOf(combat.value?.rows, "dps")).toEqual([undefined, undefined]);
  });

  it("compares shield faces, and the reconfiguration cooldown on quadrants only", () => {
    expect(cellsOf(defense.value?.rows, "shield-faces")).toEqual([
      "labels.hardpoint.controllers.faces.quadrant",
      "labels.hardpoint.controllers.faces.bubble",
    ]);
    expect(cellsOf(defense.value?.rows, "shield-reconfiguration")).toEqual([
      "2.5",
      undefined,
    ]);
  });
});
