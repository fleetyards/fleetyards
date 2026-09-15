import fallback from "@/images/fallback/store_image.webp";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";
import {
  presetCatalogue,
  presetImageUrl,
} from "@/shared/composables/usePresetImages";

export const inventoryPresets = presetCatalogue("inventories").presets;

/*
 * Spread across the presets by name rather than drawn fresh each time: two
 * inventories side by side should differ, and one inventory should keep its
 * picture across reloads and between the panel and the form that edits it.
 */
const presetForName = (name: string) => {
  if (!inventoryPresets.length) return fallback;

  let hash = 0;

  for (const ch of name) {
    hash = (hash << 5) - hash + ch.charCodeAt(0);
  }

  return inventoryPresets[Math.abs(hash) % inventoryPresets.length].url;
};

/*
 * What an inventory is shown as when nobody has given it a picture. A ship's
 * hold is shown as its ship -- it is the one thing about that hold a reader
 * already recognises, and it is why a ship's hold offers no picture of its own
 * to pick -- and everything else takes a preset off its name.
 *
 * Kept apart from the attached image so a form can offer this as the picture in
 * place while still knowing the inventory carries none of its own.
 */
export function inventoryDefaultImage(inventory: InventoryPanelRecord) {
  const shipImage = inventory.vehicle?.model?.image;

  // `url` after `mediumUrl`: only the original is guaranteed, and a ship whose
  // artwork has no sized variants is still that ship. Falling straight to a
  // preset would draw a crate over a picture we were given.
  return (
    shipImage?.mediumUrl || shipImage?.url || presetForName(inventory.name)
  );
}

export const useInventoryImage = (
  inventory: MaybeRefOrGetter<InventoryPanelRecord>,
) => {
  const defaultImage = computed(() =>
    inventoryDefaultImage(toValue(inventory)),
  );

  // The preset somebody picked, which is the whole difference between this and
  // `defaultImage`: the fallback is the one their name happens to hash to.
  const chosenImage = computed(() =>
    presetImageUrl("inventories", toValue(inventory).imagePreset),
  );

  /*
   * The inventory's own picture first, and `url` after `mediumUrl` because only
   * the original is guaranteed -- an attachment with no sized variants is still
   * the picture somebody uploaded.
   *
   * Then the ship, for a hold that rides in one. It outranks a preset on
   * purpose: a ship's hold is shown as its ship, and the form that would let
   * somebody choose otherwise is not offered for one. The column still allows a
   * preset, so the rule is kept here rather than assumed.
   *
   * Then the preset they chose, then the one their name lands on.
   */
  const image = computed(() => {
    const record = toValue(inventory);
    const own = record.image;
    const ship = record.vehicle?.model?.image;

    return (
      own?.mediumUrl ||
      own?.url ||
      ship?.mediumUrl ||
      ship?.url ||
      chosenImage.value ||
      defaultImage.value
    );
  });

  return { image, defaultImage };
};
