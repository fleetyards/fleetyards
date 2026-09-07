import { describe, expect, it } from "vitest";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ModelModule,
} from "@/services/fyApi";
import { graftEquippedModules } from "./useEquippedHardpoints";

function hardpoint(
  attributes: Partial<Hardpoint> & { id: string },
  children: Hardpoint[] = [],
): Hardpoint {
  return {
    name: attributes.id,
    category: HardpointCategoryEnum.MODULE,
    hardpoints: children,
    createdAt: "",
    updatedAt: "",
    ...attributes,
  } as Hardpoint;
}

function module(hardpoints: Hardpoint[]): ModelModule {
  return { name: "Front Torpedo Bay", hardpoints } as ModelModule;
}

describe("graftEquippedModules", () => {
  const torpedoBay = hardpoint({ id: "torpedo-launcher" });

  it("hangs a chosen module's hardpoints off the slot holding it", () => {
    const slot = hardpoint({ id: "front-module" });

    const result = graftEquippedModules([slot], {
      "front-module": module([torpedoBay]),
    });

    expect(result[0].hardpoints).toEqual([torpedoBay]);
  });

  it("keys the slot by its group when it has one", () => {
    const slot = hardpoint({ id: "front-module", groupKey: "front-group" });

    const result = graftEquippedModules([slot], {
      "front-group": module([torpedoBay]),
    });

    expect(result[0].hardpoints).toEqual([torpedoBay]);
  });

  // The default module's contents would otherwise be counted alongside the
  // contents of the module that replaced it.
  it("replaces what the slot already held rather than adding to it", () => {
    const slot = hardpoint({ id: "front-module" }, [
      hardpoint({ id: "cargo-grid" }),
    ]);

    const result = graftEquippedModules([slot], {
      "front-module": module([torpedoBay]),
    });

    expect(result[0].hardpoints).toEqual([torpedoBay]);
  });

  it("leaves a slot with no choice made alone", () => {
    const slot = hardpoint({ id: "rear-module" }, [
      hardpoint({ id: "cargo-grid" }),
    ]);

    const result = graftEquippedModules([slot], { "front-module": null });

    expect(result[0]).toBe(slot);
  });

  it("returns the list untouched when nothing is equipped", () => {
    const slots = [hardpoint({ id: "front-module" })];

    expect(graftEquippedModules(slots, {})).toBe(slots);
    expect(graftEquippedModules(slots, undefined)).toBe(slots);
  });

  it("survives a loadout that has not loaded yet", () => {
    expect(graftEquippedModules(undefined, {})).toEqual([]);
  });
});
