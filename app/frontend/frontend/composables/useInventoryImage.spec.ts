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

  /*
   * The serializer emits the sized variants only for an attachment it could
   * build representations for. One that arrives with just its original is
   * still a picture somebody chose, and drawing a preset over it would look
   * like the upload was lost.
   */
  it("shows an attachment that has only an original", () => {
    const { image } = useInventoryImage(
      inventory({ image: { url: "https://example.test/original.tiff" } }),
    );

    expect(image.value).toBe("https://example.test/original.tiff");
  });

  it("shows a ship image that has only an original", () => {
    const { image, defaultImage } = useInventoryImage(
      inventory({
        vehicle: {
          id: "v-1",
          name: "North Star",
          model: { image: { url: "https://example.test/ship.tiff" } },
        },
      }),
    );

    expect(image.value).toBe("https://example.test/ship.tiff");
    expect(defaultImage.value).toBe("https://example.test/ship.tiff");
  });

  it("prefers a sized variant over the original", () => {
    const { image } = useInventoryImage(
      inventory({
        image: {
          url: "https://example.test/original.png",
          mediumUrl: "https://example.test/medium.png",
        },
      }),
    );

    expect(image.value).toBe("https://example.test/medium.png");
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

  /*
   * The picture somebody picked, as opposed to the one their inventory's name
   * happens to hash to. It is what `defaultImage` is the fallback for, so the
   * form still knows what it would show without a choice.
   */
  it("prefers a chosen preset over the one the name lands on", () => {
    const chosen = inventoryPresets[inventoryPresets.length - 1];

    const { image, defaultImage } = useInventoryImage(
      inventory({ name: "Locker", imagePreset: chosen.key }),
    );

    expect(image.value).toBe(chosen.url);
    expect(defaultImage.value).toBe(
      inventoryDefaultImage(inventory({ name: "Locker" })),
    );
  });

  it("ignores a preset naming art that is no longer shipped", () => {
    const { image } = useInventoryImage(
      inventory({ name: "Locker", imagePreset: "retired_art" }),
    );

    expect(image.value).toBe(
      inventoryDefaultImage(inventory({ name: "Locker" })),
    );
  });

  /*
   * The form that would let somebody pick one is not offered for a ship's hold,
   * but the column allows a preset and the API is not the only way rows get
   * written. A hold that rides in a ship is shown as that ship, full stop.
   */
  it("shows a ship's hold as its ship even when a preset was stored", () => {
    const { image } = useInventoryImage(
      inventory({
        imagePreset: inventoryPresets[0].key,
        vehicle: { id: "v-1", name: "North Star", model: { image: shipImage } },
      }),
    );

    expect(image.value).toBe(shipImage.mediumUrl);
  });

  // Only the original is guaranteed, so a ship whose art has no sized variants
  // is still that ship rather than falling through to a preset.
  it("takes the ship's original when it has no sized variants", () => {
    const { image } = useInventoryImage(
      inventory({
        imagePreset: inventoryPresets[0].key,
        vehicle: {
          id: "v-1",
          name: "North Star",
          model: { image: { url: "https://example.test/original.jpg" } },
        },
      }),
    );

    expect(image.value).toBe("https://example.test/original.jpg");
  });

  // A ship's hold is shown as its ship, and offers no picture of its own to
  // pick -- so nothing can ever overrule that.
  it("still shows a ship's hold as its ship", () => {
    const { image } = useInventoryImage(
      inventory({
        vehicle: { id: "v-1", name: "North Star", model: { image: shipImage } },
      }),
    );

    expect(image.value).toBe(shipImage.mediumUrl);
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
