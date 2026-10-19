import { describe, expect, it } from "vitest";
import {
  craftComponent,
  craftEquipment,
  craftedFactors,
} from "./craftedRecord";

const modifier = (propertyKey: string, from = 0.9, to = 1.1) => ({
  propertyKey,
  startQuality: 0,
  endQuality: 1000,
  modifierAtStart: from,
  modifierAtEnd: to,
});

const slot = (position: number, ...modifiers: ReturnType<typeof modifier>[]) =>
  ({ position, modifiers }) as never;

describe("craftedFactors", () => {
  // Every ramp is 1.0x at the neutral grade, the catalogue's own figure.
  it("leaves a blank slot at the catalogue's figure", () => {
    const factors = craftedFactors(
      [slot(1, modifier("gpp_shield_maxhealth"))],
      {},
    );

    expect(factors.get("gpp_shield_maxhealth")?.value).toBeCloseTo(1);
  });

  it("composes two slots moving one stat by multiplying", () => {
    const factors = craftedFactors(
      [
        slot(1, modifier("gpp_shield_maxhealth")),
        slot(2, modifier("gpp_shield_maxhealth")),
      ],
      { 1: 1000, 2: 1000 },
    );

    expect(factors.get("gpp_shield_maxhealth")?.value).toBeCloseTo(1.21);
  });

  // A power plant's pips are added, not scaled: multiplying would turn 28 into
  // -28 rather than 27.
  it("adds an additive ramp's whole amounts across slots", () => {
    const pips = (position: number) =>
      ({
        position,
        modifiers: [
          {
            propertyKey: "gpp_itemresource_powergeneration",
            ramp: "linear_integer_additive",
            startQuality: 0,
            endQuality: 1000,
            modifierAtStart: -1,
            modifierAtEnd: 1,
          },
        ],
      }) as never;

    const factors = craftedFactors([pips(1), pips(2)], { 1: 0, 2: 1000 });

    expect(factors.get("gpp_itemresource_powergeneration")).toEqual({
      additive: true,
      value: 0,
    });

    const crafted = craftComponent(
      { name: "JS-300", typeData: { powerBase: 28 } } as never,
      craftedFactors([pips(1)], { 1: 0 }),
    );

    expect((crafted.typeData as { powerBase: number }).powerBase).toBe(27);
  });
});

describe("craftComponent", () => {
  it("scales the figures a recipe moves and keeps the rest", () => {
    const crafted = craftComponent(
      { name: "Bulwark", typeData: { maxHealth: 1000, maxRegen: 50 } } as never,
      new Map([["gpp_shield_maxhealth", { additive: false, value: 1.1 }]]),
    );

    expect(crafted.typeData).toEqual({ maxHealth: 1100, maxRegen: 50 });
  });

  // Damage is split across the types a weapon deals.
  it("scales every type of damage a weapon deals", () => {
    const crafted = craftComponent(
      {
        name: "Repeater",
        typeData: { damagePerShot: { energy: 10, physical: 0 } },
      } as never,
      new Map([["gpp_weapon_damage", { additive: false, value: 1.2 }]]),
    );

    expect(
      (crafted.typeData as { damagePerShot: Record<string, number> })
        .damagePerShot.energy,
    ).toBeCloseTo(12);
  });

  it("scales a part's integrity", () => {
    const crafted = craftComponent(
      {
        name: "Bulwark",
        typeData: {},
        durability: { health: 500, mass: 9 },
      } as never,
      new Map([["gpp_health_maxhealth", { additive: false, value: 1.2 }]]),
    );

    expect(crafted.durability).toEqual({ health: 600, mass: 9 });
  });

  it("does not touch the catalogue's own record", () => {
    const stock = { name: "Bulwark", typeData: { maxHealth: 1000 } };

    craftComponent(
      stock as never,
      new Map([["gpp_shield_maxhealth", { additive: false, value: 1.1 }]]),
    );

    expect(stock.typeData.maxHealth).toBe(1000);
  });
});

describe("craftEquipment", () => {
  it("scales an armour's damage reduction", () => {
    const crafted = craftEquipment(
      { name: "Antium", damageReduction: 0.3 } as never,
      new Map([
        ["gpp_armor_damagemitigation", { additive: false, value: 1.1 }],
      ]),
    );

    expect(crafted.damageReduction).toBeCloseTo(0.33);
  });
});
