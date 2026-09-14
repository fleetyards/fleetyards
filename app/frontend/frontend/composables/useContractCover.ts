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

const coverByKind: Record<string, string> = {};
const extByKind: Record<string, string> = {};

for (const [path, mod] of Object.entries(covers)) {
  const match = path.match(/contracts\/([^./]+)\.(webp|jpg|jpeg|png)$/);
  if (!match) continue;

  const [, stem, ext] = match;
  // `transport_alt1` belongs to `transport`; the plain stem wins on a tie
  // because it sorts first and only a higher-priority format overrides.
  const kind = stem.split("_alt")[0];

  if ((FORMAT_PRIORITY[ext] ?? 0) < (FORMAT_PRIORITY[extByKind[kind]] ?? 0)) {
    continue;
  }

  coverByKind[kind] = mod.default;
  extByKind[kind] = ext;
}

const standInFor = (kind: string) => {
  const stem = STAND_IN_FOR_KIND[kind];
  if (!stem) return undefined;

  const entry = Object.entries(standIns).find(([path]) =>
    path.includes(`/${stem}.webp`),
  );

  return entry?.[1].default;
};

export const useContractCover = () => {
  /*
   * The fleet's own art wins: a fleet that uploaded a cover for this kind in its
   * settings should see that and not the stand-in. Then anything dropped into
   * images/contracts/, then the mission art that comes closest, then the generic
   * placeholder.
   */
  const resolve = (
    contract?: FleetContract | FleetContractDetail | null,
    fleet?: Fleet | null,
  ) => {
    const kind = contract?.kind;
    if (!kind) return fallback;

    const own =
      fleet?.contractCovers?.[kind as keyof typeof fleet.contractCovers];

    return (
      own?.mediumUrl ??
      own?.url ??
      coverByKind[kind] ??
      standInFor(kind) ??
      fallback
    );
  };

  return { resolve };
};
