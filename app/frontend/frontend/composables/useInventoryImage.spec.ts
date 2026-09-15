import { describe, expect, it } from "vitest";
import {
  inventoryDefaultImage,
  inventoryPresets,
  useInventoryImage,
} from "./useInventoryImage";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";

const inventory = (
  overrides: Partial<InventoryPanelRecord> = {},
): InventoryPanelRecord => ({
  id: "inventory-1",
  name: "North Star",
  entriesCount: 0,
  ...overrides,
});

const shipImage = { mediumUrl: "https://example.test/north-star.jpg" };

describe("useInventoryImage", () => {
  it("shows a ship's hold as its ship", () => {
    const { image, defaultImage } = useInventoryImage(
      inventory({
        vehicle: { id: "v-1", name: "North Star", model: { image: shipImage } },
      }),
    );

    expect(image.value).toBe(shipImage.mediumUrl);
    expect(defaultImage.value).toBe(shipImage.mediumUrl);
  });

  // The picture somebody chose outranks the one the ship lends it.
  it("prefers the inventory's own picture over the ship's", () => {
    const own = { mediumUrl: "https://example.test/own.jpg" };
    const { image, defaultImage } = useInventoryImage(
      inventory({
        image: own,
        vehicle: { id: "v-1", name: "North Star", model: { image: shipImage } },
      }),
    );

    expect(image.value).toBe(own.mediumUrl);
    // Still what the form offers as the picture it would fall back to.
    expect(defaultImage.value).toBe(shipImage.mediumUrl);
  });

  it("falls back to a preset for an inventory no ship carries", () => {
    const { image } = useInventoryImage(inventory({ name: "Locker" }));

    expect(image.value).toBeTruthy();
    expect(image.value).not.toBe(shipImage.mediumUrl);
  });

  // Dropping art into the folder is meant to be the whole change.
  it("takes its presets from the folder rather than a list", () => {
    expect(inventoryPresets.length).toBeGreaterThan(0);
    expect(inventoryPresets.every((preset) => !!preset.url)).toBe(true);
  });

  // Two inventories side by side should not show the same picture.
  it("spreads names across the presets it has", () => {
    if (inventoryPresets.length < 2) return;

    const names = ["Locker", "Hold", "Depot", "Cache", "Bay", "Vault"];
    const chosen = new Set(
      names.map((name) => inventoryDefaultImage(inventory({ name }))),
    );

    expect(chosen.size).toBeGreaterThan(1);
  });

  // Same inventory, same picture -- across reloads, and between the panel and
  // the form that edits it.
  it("picks the same placeholder for the same name every time", () => {
    expect(inventoryDefaultImage(inventory({ name: "Locker" }))).toBe(
      inventoryDefaultImage(inventory({ name: "Locker" })),
    );
  });
});
