import fallback from "@/images/fallback/store_image.webp";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";

// Globbed rather than listed, the way the mission and contract covers are, so
// another placeholder joins the rotation by being dropped into the folder.
const presets = import.meta.glob<{ default: string }>(
  "@/images/inventories/*.{webp,jpg,jpeg,png}",
  { eager: true },
);

/*
 * Art the app already ships, so the rotation is more than two pictures wide
 * without carrying a second copy of anything. Keyed by name rather than globbed
 * wholesale: these are page backdrops, and only the ones that read as a place
 * goods are kept belong here -- and the heaviest of them (bg-6 through bg-8,
 * over a megabyte each) have no business behind a panel this size.
 *
 * Purpose-made art in images/inventories/ is preferred over all of it.
 */
const sharedArt = import.meta.glob<{ default: string }>(
  "@/images/{bg-hangar,bg-1,bg-2,bg-3,bg-5,bg-9}.webp",
  { eager: true },
);

const FORMAT_PRIORITY: Record<string, number> = {
  webp: 3,
  png: 2,
  jpg: 1,
  jpeg: 1,
};

const urlByPreset: Record<string, string> = {};
const extByPreset: Record<string, string> = {};

for (const [path, mod] of Object.entries(presets)) {
  const match = path.match(/inventories\/([^./]+)\.(webp|jpg|jpeg|png)$/);
  if (!match) continue;

  const [, stem, ext] = match;

  // One picture per stem: `locker.webp` and `locker.jpg` are the same art in
  // two formats, and only the better format may replace what is already here.
  if ((FORMAT_PRIORITY[ext] ?? 0) < (FORMAT_PRIORITY[extByPreset[stem]] ?? 0)) {
    continue;
  }

  urlByPreset[stem] = mod.default;
  extByPreset[stem] = ext;
}

for (const [path, mod] of Object.entries(sharedArt)) {
  const match = path.match(/images\/([^./]+)\.webp$/);
  if (!match) continue;

  const stem = match[1];

  // Never over a file of the same name in images/inventories/: that one was put
  // there for this, and this is only what was lying around.
  if (urlByPreset[stem]) continue;

  urlByPreset[stem] = mod.default;
  extByPreset[stem] = "webp";
}

// Sorted, so the rotation does not depend on the order the bundler happened to
// walk the folders in -- which would hand the same inventory a different
// picture between two builds.
export const inventoryPresets = Object.keys(urlByPreset)
  .sort()
  .map((key) => ({ key, url: urlByPreset[key] }));

/*
 * Spread across the presets by name rather than drawn fresh each time: two
 * inventories side by side should differ, and one inventory should keep its
 * picture across reloads and between the panel and the form that edits it.
 */
const presetFor = (name: string) => {
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
 * already recognises -- and everything else takes a preset.
 *
 * Kept apart from the attached image so a form can offer this as the picture in
 * place while still knowing the inventory carries none of its own.
 */
export function inventoryDefaultImage(inventory: InventoryPanelRecord) {
  const shipImage = inventory.vehicle?.model?.image;

  // `url` after `mediumUrl`: only the original is guaranteed, and a ship whose
  // artwork has no sized variants is still that ship. Falling straight to a
  // preset would draw a crate over a picture we were given.
  return shipImage?.mediumUrl || shipImage?.url || presetFor(inventory.name);
}

export const useInventoryImage = (
  inventory: MaybeRefOrGetter<InventoryPanelRecord>,
) => {
  const defaultImage = computed(() =>
    inventoryDefaultImage(toValue(inventory)),
  );

  const image = computed(() => {
    const own = toValue(inventory).image;

    return own?.mediumUrl || own?.url || defaultImage.value;
  });

  return { image, defaultImage };
};
