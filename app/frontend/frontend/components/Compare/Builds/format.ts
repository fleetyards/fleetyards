import type { RouteLocationRaw } from "vue-router";
import {
  ScDataDiffCatalogueEnum,
  type ScDataBuild,
  type ScDataDiffField,
} from "@/services/fyApi";

export const fieldKey = (field: string) =>
  (field.split(".").pop() || field).replace(/_(\w)/g, (_, c: string) =>
    c.toUpperCase(),
  );

// The unit `toNumber` formats a fact with. A fact not listed is a plain count.
export const FIELD_UNITS: Record<string, string> = {
  cargo: "cargo",
  volume: "cargo",
  personalInventory: "cargo",
  mainAcceleration: "acceleration",
  retroAcceleration: "acceleration",
  scmSpeed: "speed",
  scmSpeedBoosted: "speed",
  reverseSpeedBoosted: "speed",
  maxSpeed: "speed",
  pitch: "rotation",
  pitchBoosted: "rotation",
  yaw: "rotation",
  yawBoosted: "rotation",
  roll: "rotation",
  rollBoosted: "rotation",
  groundMaxSpeed: "speed",
  groundReverseSpeed: "speed",
  groundAcceleration: "acceleration",
  groundDeceleration: "acceleration",
  rateOfFire: "rateOfFire",
  range: "distance",
  damageReduction: "percent",
};

// How far a fact moved, or undefined when either side is not a number.
export const movement = (field: ScDataDiffField) => {
  const { from, to } = field;
  if (typeof from !== "number" || typeof to !== "number" || from === 0) {
    return undefined;
  }

  const percent = Math.round(((to - from) / Math.abs(from)) * 100);
  if (percent === 0) return undefined;

  return `${percent > 0 ? "+" : "−"}${Math.abs(percent)}%`;
};

const ROUTES: Partial<Record<ScDataDiffCatalogueEnum, string>> = {
  models: "ship",
  loadouts: "ship",
  components: "component",
  equipment: "equipment-item",
  commodities: "commodity",
  blueprints: "blueprint",
  missions: "mission",
  factions: "faction",
  locations: "location",
};

export const entryRoute = (
  catalogue: ScDataDiffCatalogueEnum,
  slug?: string | null,
): RouteLocationRaw | undefined => {
  const name = ROUTES[catalogue];

  return name && slug ? { name, params: { slug } } : undefined;
};

const release = (version: string) => version.split("-")[0] as string;

// `4.10.3-live.13165946` as a reader says it: `LIVE 4.10.3 (13165946)`.
export const buildLabel = (
  build: Pick<ScDataBuild, "environment" | "version">,
) =>
  `${build.environment.toUpperCase()} ${release(build.version)} (${build.version.split(".").pop()})`;

type Build = Pick<ScDataBuild, "environment" | "version">;

/**
 * The comparison a reader most likely came for: live against a preview while
 * one is ahead of it, otherwise the live patch against the one before. The
 * sources say what is served, where the builds also list one still loading.
 */
export const defaultPair = (
  builds: Build[],
  sources: Build[],
): { from: string; to: string } | undefined => {
  const current = sources.find((source) => source.environment === "live");
  const preview = sources.find((source) => source.environment === "ptu");
  if (!current) return undefined;

  if (preview) return { from: current.version, to: preview.version };

  const live = builds.filter((build) => build.environment === "live");
  const older = live.slice(
    live.findIndex((build) => build.version === current.version) + 1,
  );
  const previous =
    older.find(
      (build) => release(build.version) !== release(current.version),
    ) || older[0];

  return previous && { from: previous.version, to: current.version };
};

// A slot's key as a reader says it: `hardpoint_radar_front` is "Radar front".
export const readableField = (field: string) => {
  const words = (field.split(".").pop() || field)
    .replace(/^hardpoint_/, "")
    .replace(/_/g, " ")
    .trim();

  return words.charAt(0).toUpperCase() + words.slice(1);
};

export const SLOT_POSITIONS = [
  "left",
  "right",
  "front",
  "rear",
  "top",
  "bottom",
  "upper",
  "lower",
  "nose",
  "tail",
  "side",
  "mid",
  "center",
  "wing",
  "inner",
  "outer",
] as const;

// Where on the ship a slot is: the words of its key that name a place, and its
// number, which tell apart the slots of one kind.
export const slotPosition = (
  field: string,
  translate: (position: (typeof SLOT_POSITIONS)[number]) => string,
) =>
  field
    .toLowerCase()
    .split("_")
    .flatMap((word) => {
      const position = SLOT_POSITIONS.find((item) => item === word);
      if (position) return [translate(position)];

      return /^\d+$/.test(word) ? [String(Number(word))] : [];
    })
    .join(" ");
