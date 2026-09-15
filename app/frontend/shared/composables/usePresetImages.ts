/*
 * The art the app ships for records nobody has given a picture to, and the one
 * place that knows where it lives. Three folders used to carry a copy each of
 * the same glob, the same format-priority table and the same "`x_alt1` belongs
 * to `x`" rule; a fourth was about to.
 *
 * Adding a picture is still only dropping a file into the folder.
 */

type PresetImage = {
  key: string;
  url: string;
  // Which filter chip the picker files it under. Absent for a catalogue whose
  // art is not divided -- an inventory picture is not "of" anything.
  group?: string;
};

export type PresetCatalogueName = "missions" | "contracts" | "inventories";

export type PresetCatalogue = {
  presets: PresetImage[];
  groups: string[];
  // Where the picker finds a name for a group. The keys are the same ones the
  // record's own form labels its type select with, so the chips and the select
  // never disagree.
  groupLabelPrefix?: string;
};

// webp first, because every one of these is shipped as webp plus a fallback and
// the two are the same picture -- only a better format may replace what is
// already held for a stem.
const FORMAT_PRIORITY: Record<string, number> = {
  webp: 3,
  png: 2,
  jpg: 1,
  jpeg: 1,
};

type GlobResult = Record<string, { default: string }>;

const folders: Record<PresetCatalogueName, GlobResult> = {
  missions: import.meta.glob<{ default: string }>(
    "@/images/missions/*.{webp,jpg,jpeg,png}",
    { eager: true },
  ),
  contracts: import.meta.glob<{ default: string }>(
    "@/images/contracts/*.{webp,jpg,jpeg,png}",
    { eager: true },
  ),
  inventories: import.meta.glob<{ default: string }>(
    "@/images/inventories/*.{webp,jpg,jpeg,png}",
    { eager: true },
  ),
};

// A mission picture is named after the category it illustrates, so the stem is
// the group -- but `ship_combat_alt1` has to land under `ship_combat` and not
// under `ship`, which is why the list is matched rather than the name split.
const MISSION_CATEGORIES = [
  "other",
  "ship_combat",
  "ground_combat",
  "combined_combat",
  "mining",
  "salvage",
  "cargo_hauling",
  "exploration",
];

const GROUPS_BY_CATALOGUE: Partial<
  Record<PresetCatalogueName, { known?: string[]; labelPrefix: string }>
> = {
  missions: {
    known: MISSION_CATEGORIES,
    labelPrefix: "labels.fleets.missions.categories",
  },
  // No known list: a contract kind is whatever art turned up for it, and the
  // three the model allows all have a label already.
  contracts: { labelPrefix: "labels.fleets.contracts.kind" },
};

const groupFor = (
  catalogue: PresetCatalogueName,
  stem: string,
): string | undefined => {
  const config = GROUPS_BY_CATALOGUE[catalogue];
  if (!config) return undefined;

  if (config.known) {
    return config.known.find(
      (group) => stem === group || stem.startsWith(`${group}_`),
    );
  }

  return stem.split("_alt")[0];
};

const build = (catalogue: PresetCatalogueName): PresetCatalogue => {
  const urlByKey: Record<string, string> = {};
  const extByKey: Record<string, string> = {};

  for (const [path, mod] of Object.entries(folders[catalogue])) {
    const match = path.match(/\/([^/.]+)\.(webp|jpg|jpeg|png)$/);
    if (!match) continue;

    const [, key, ext] = match;

    // One picture per name: `placeholder-3.webp` and `placeholder-3.jpg` are
    // the same art in two formats, and only the better format may replace what
    // is already held.
    if ((FORMAT_PRIORITY[ext] ?? 0) < (FORMAT_PRIORITY[extByKey[key]] ?? 0)) {
      continue;
    }

    urlByKey[key] = mod.default;
    extByKey[key] = ext;
  }

  const config = GROUPS_BY_CATALOGUE[catalogue];

  /*
   * Sorted, so the order does not depend on the order the bundler happened to
   * walk the folder in -- which would reshuffle the grid between two builds,
   * and hand an inventory a different picture each time.
   *
   * Inside a group the plain stem leads: `mining` is the mining cover and
   * `mining_alt1` is an alternative to it, so it is the one to offer first.
   */
  const presets = Object.keys(urlByKey)
    .sort((a, b) => {
      const groupA = groupFor(catalogue, a) ?? "";
      const groupB = groupFor(catalogue, b) ?? "";

      if (groupA !== groupB) {
        if (config?.known) {
          return config.known.indexOf(groupA) - config.known.indexOf(groupB);
        }

        return groupA.localeCompare(groupB);
      }

      if (a === groupA) return -1;
      if (b === groupB) return 1;

      return a.localeCompare(b);
    })
    .map((key) => ({
      key,
      url: urlByKey[key],
      group: groupFor(catalogue, key),
    }));

  const groups = presets
    .map((preset) => preset.group)
    .filter(
      (group, index, all): group is string =>
        !!group && all.indexOf(group) === index,
    );

  return { presets, groups, groupLabelPrefix: config?.labelPrefix };
};

const catalogues = {} as Record<PresetCatalogueName, PresetCatalogue>;

export const presetCatalogue = (name: PresetCatalogueName): PresetCatalogue => {
  catalogues[name] ??= build(name);

  return catalogues[name];
};

export const presetImageUrl = (
  name: PresetCatalogueName,
  key?: string | null,
): string | undefined =>
  (key && presetCatalogue(name).presets.find((p) => p.key === key)?.url) ||
  undefined;
