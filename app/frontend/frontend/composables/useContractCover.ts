import type {
  Fleet,
  FleetContract,
  FleetContractDetail,
} from "@/services/fyApi";
import fallback from "@/images/fallback/store_image.webp";

const covers = import.meta.glob<{ default: string }>(
  "@/images/contracts/*.{webp,jpg,jpeg,png}",
  { eager: true },
);

// Mission art that comes closest, until a kind has its own. Keyed rather than
// guessed so replacing it is one line, and so a missing file degrades to the
// generic placeholder instead of to whatever happens to sort first.
const standIns = import.meta.glob<{ default: string }>(
  "@/images/missions/{cargo_hauling,mining,other}.{webp,jpg}",
  { eager: true },
);

const FORMAT_PRIORITY: Record<string, number> = {
  webp: 3,
  png: 2,
  jpg: 1,
  jpeg: 1,
};

const STAND_IN_FOR_KIND: Record<string, string> = {
  transport: "cargo_hauling",
  procurement: "other",
  crafting: "mining",
};

// Keyed by preset rather than by kind: `transport` and `transport_alt1` are two
// pictures a transport contract may be given, and the form offers both. Keying
// by kind is what made an alternate overwrite the base instead of joining it,
// so the rotation this folder's README promises never actually existed.
const urlByPreset: Record<string, string> = {};
const extByPreset: Record<string, string> = {};
const presetsByKind: Record<string, string[]> = {};

for (const [path, mod] of Object.entries(covers)) {
  const match = path.match(/contracts\/([^./]+)\.(webp|jpg|jpeg|png)$/);
  if (!match) continue;

  const [, stem, ext] = match;

  if ((FORMAT_PRIORITY[ext] ?? 0) < (FORMAT_PRIORITY[extByPreset[stem]] ?? 0)) {
    continue;
  }

  if (!urlByPreset[stem]) {
    const kind = stem.split("_alt")[0];

    if (!presetsByKind[kind]) presetsByKind[kind] = [];
    presetsByKind[kind].push(stem);
  }

  urlByPreset[stem] = mod.default;
  extByPreset[stem] = ext;
}

// The plain stem first, then the alternates in name order, so the grid does not
// reshuffle between builds.
for (const kind of Object.keys(presetsByKind)) {
  presetsByKind[kind].sort((a, b) => {
    if (a === kind) return -1;
    if (b === kind) return 1;
    return a.localeCompare(b);
  });
}

const standInFor = (kind: string) => {
  const stem = STAND_IN_FOR_KIND[kind];
  if (!stem) return undefined;

  const entry = Object.entries(standIns).find(([path]) =>
    path.includes(`/${stem}.webp`),
  );

  return entry?.[1].default;
};

export type ContractPresetOption = {
  key: string;
  url: string;
};

type ContractLike = FleetContract | FleetContractDetail;

export const useContractCover = () => {
  /*
   * The contract's own art wins -- somebody chose it for this job. Then the
   * preset they picked, then the fleet's cover for this kind from its settings,
   * then anything dropped into images/contracts/, then the mission art that
   * comes closest, then the generic placeholder.
   */
  const resolve = (contract?: ContractLike | null, fleet?: Fleet | null) => {
    const kind = contract?.kind;
    if (!kind) return fallback;

    const uploaded = contract?.coverImage;
    if (uploaded) {
      return (
        uploaded.mediumUrl || uploaded.smallUrl || uploaded.url || fallback
      );
    }

    const preset = contract?.coverImagePreset;
    if (preset && urlByPreset[preset]) return urlByPreset[preset];

    const own =
      fleet?.contractCovers?.[kind as keyof typeof fleet.contractCovers];

    return (
      own?.mediumUrl ??
      own?.url ??
      urlByPreset[kind] ??
      standInFor(kind) ??
      fallback
    );
  };

  // What the form offers for a kind. Empty until that kind has art of its own --
  // there is nothing to choose between while it is borrowing a mission cover.
  const presetsFor = (kind: string): ContractPresetOption[] =>
    (presetsByKind[kind] ?? []).map((key) => ({ key, url: urlByPreset[key] }));

  const presetUrl = (key: string | null | undefined) =>
    (key && urlByPreset[key]) || undefined;

  return { resolve, presetsFor, presetUrl };
};
