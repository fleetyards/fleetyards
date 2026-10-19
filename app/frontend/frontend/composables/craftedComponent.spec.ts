import { describe, expect, it } from "vitest";
import {
  craftedComponent,
  craftedFactors,
} from "@/frontend/composables/craftedComponent";
import {
  type BlueprintCostModifier,
  type BlueprintCostSlot,
  BlueprintRampEnum,
  type LoadoutComponentRef,
} from "@/services/fyApi";

const modifier = (
  propertyKey: string,
  overrides: Partial<BlueprintCostModifier> = {},
): BlueprintCostModifier => ({
  propertyKey,
  name: propertyKey,
  ramp: BlueprintRampEnum.LINEAR,
  startQuality: 0,
  endQuality: 1000,
  modifierAtStart: 0.8,
  modifierAtEnd: 1.2,
  ...overrides,
});

const slot = (
  position: number,
  modifiers: BlueprintCostModifier[],
): BlueprintCostSlot => ({ position, options: [], modifiers });

const shield = {
  id: "shield",
  name: "Shield",
  typeData: { maxHealth: 1000, maxRegen: 100 },
} as LoadoutComponentRef;

const at = (qualities: Record<number, number>) => (position: number) =>
  qualities[position] ?? 500;

describe("craftedFactors", () => {
  it("multiplies two slots moving the same stat", () => {
    const factors = craftedFactors(
      [
        slot(0, [modifier("gpp_shield_maxhealth")]),
        slot(1, [modifier("gpp_shield_maxhealth")]),
      ],
      at({ 0: 1000, 1: 1000 }),
    );

    expect(factors.get("gpp_shield_maxhealth")).toBeCloseTo(1.44);
  });

  it("skips a modifier that carries no figures", () => {
    const factors = craftedFactors(
      [
        slot(0, [
          modifier("gpp_itemresource_powergeneration", {
            modifierAtStart: null,
            modifierAtEnd: null,
          }),
        ]),
      ],
      at({ 0: 1000 }),
    );

    expect(factors.size).toBe(0);
  });
});

describe("craftedComponent", () => {
  it("reads as the catalogue's part at the neutral grade", () => {
    const crafted = craftedComponent(
      shield,
      [slot(0, [modifier("gpp_shield_maxhealth")])],
      at({}),
    );

    expect(crafted.typeData).toEqual(shield.typeData);
  });

  it("scales the field the stat maps to and leaves the rest", () => {
    const crafted = craftedComponent(
      shield,
      [slot(0, [modifier("gpp_shield_maxhealth")])],
      at({ 0: 0 }),
    );

    expect(crafted.typeData).toEqual({ maxHealth: 800, maxRegen: 100 });
    expect(shield.typeData).toEqual({ maxHealth: 1000, maxRegen: 100 });
  });

  it("scales every damage type of a weapon", () => {
    const gun = {
      id: "gun",
      name: "Gun",
      typeData: { fireRate: 600, damagePerShot: { physical: 100, energy: 0 } },
    } as LoadoutComponentRef;

    const crafted = craftedComponent(
      gun,
      [slot(0, [modifier("gpp_weapon_damage")])],
      at({ 0: 1000 }),
    );

    expect(crafted.typeData).toEqual({
      fireRate: 600,
      damagePerShot: { physical: 120, energy: 0 },
    });
  });

  it("leaves a stat the catalogue holds no figure for alone", () => {
    const crafted = craftedComponent(
      shield,
      [slot(0, [modifier("gpp_health_maxhealth")])],
      at({ 0: 1000 }),
    );

    expect(crafted.typeData).toEqual(shield.typeData);
  });
});
