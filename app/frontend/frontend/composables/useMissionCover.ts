import type { Mission, MissionExtended } from "@/services/fyApi";
import fallback from "@/images/fallback/store_image.webp";

const covers = import.meta.glob<{ default: string }>(
  "@/images/missions/*.{webp,jpg,jpeg,png}",
  { eager: true },
);

// Map preset key (filename stem, e.g. "ship_combat" or "ship_combat_alt1") → asset URL
const coverByPreset: Record<string, string> = {};
// Track which extension was picked per stem, so we only override with a
// higher-priority format (webp wins).
const extByPreset: Record<string, string> = {};
// Map category → preset keys, ordered alphabetically (default `<category>` first)
const presetsByCategory: Record<string, string[]> = {};

const FORMAT_PRIORITY: Record<string, number> = {
  webp: 3,
  png: 2,
  jpg: 1,
  jpeg: 1,
};

const KNOWN_CATEGORIES = [
  "other",
  "ship_combat",
  "ground_combat",
  "combined_combat",
  "mining",
  "salvage",
  "cargo_hauling",
  "exploration",
];

function tryMatchCategory(stem: string): string | undefined {
  return KNOWN_CATEGORIES.find(
    (cat) => stem === cat || stem.startsWith(`${cat}_`),
  );
}

for (const [path, mod] of Object.entries(covers)) {
  const match = path.match(/missions\/([^./]+)\.(webp|jpg|jpeg|png)$/);
  if (!match) continue;
  const stem = match[1];
  const ext = match[2];

  const existingPriority = FORMAT_PRIORITY[extByPreset[stem]] ?? 0;
  const newPriority = FORMAT_PRIORITY[ext] ?? 0;
  if (newPriority < existingPriority) continue;

  if (!coverByPreset[stem]) {
    const category = stem.split("_alt")[0];
    const baseCategory =
      stem === category ? stem : (tryMatchCategory(stem) ?? category);

    if (!presetsByCategory[baseCategory]) presetsByCategory[baseCategory] = [];
    presetsByCategory[baseCategory].push(stem);
  }

  coverByPreset[stem] = mod.default;
  extByPreset[stem] = ext;
}

// Sort each category list: exact-match category first, then variants alphabetically
for (const category of Object.keys(presetsByCategory)) {
  presetsByCategory[category].sort((a, b) => {
    if (a === category) return -1;
    if (b === category) return 1;
    return a.localeCompare(b);
  });
}

type CoverImageHolder = {
  mediumUrl?: string;
  smallUrl?: string;
  url?: string;
};

type MissionLike =
  | Mission
  | MissionExtended
  | {
      category?: string;
      coverImage?: CoverImageHolder | null;
      coverImagePreset?: string | null;
    };

export type MissionPresetOption = {
  key: string;
  url: string;
};

export const useMissionCover = () => {
  const resolve = (mission?: MissionLike | null) => {
    if (!mission) return fallback;

    const uploaded = (mission as { coverImage?: CoverImageHolder | null })
      .coverImage;
    if (uploaded) {
      return (
        uploaded.mediumUrl || uploaded.smallUrl || uploaded.url || fallback
      );
    }

    const preset = (mission as { coverImagePreset?: string | null })
      .coverImagePreset;
    if (preset && coverByPreset[preset]) return coverByPreset[preset];

    return (
      (mission.category && coverByPreset[mission.category as string]) ||
      fallback
    );
  };

  const presetsFor = (category: string): MissionPresetOption[] => {
    const stems = presetsByCategory[category] ?? [];
    return stems.map((key) => ({ key, url: coverByPreset[key] }));
  };

  const presetUrl = (key: string | null | undefined) =>
    (key && coverByPreset[key]) || undefined;

  return { resolve, presetsFor, presetUrl };
};
