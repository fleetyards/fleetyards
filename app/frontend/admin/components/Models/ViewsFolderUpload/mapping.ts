import { type ModelUpdateInput } from "@/services/fyAdminApi";

export const VIEW_FIELDS = [
  "topView",
  "portView",
  "frontView",
  "angledView",
  "topViewColored",
  "portViewColored",
  "frontViewColored",
  "angledViewColored",
  "extendedTopView",
  "extendedPortView",
  "extendedFrontView",
  "extendedAngledView",
  "extendedTopViewColored",
  "extendedPortViewColored",
  "extendedFrontViewColored",
  "extendedAngledViewColored",
  "landedTopView",
  "landedPortView",
  "landedFrontView",
  "landedAngledView",
  "landedTopViewColored",
  "landedPortViewColored",
  "landedFrontViewColored",
  "landedAngledViewColored",
  "angledRearView",
  "bottomView",
  "rearView",
  "starboardView",
  "angledRearViewColored",
  "bottomViewColored",
  "rearViewColored",
  "starboardViewColored",
  "extendedAngledRearView",
  "extendedBottomView",
  "extendedRearView",
  "extendedStarboardView",
  "extendedAngledRearViewColored",
  "extendedBottomViewColored",
  "extendedRearViewColored",
  "extendedStarboardViewColored",
  "landedAngledRearView",
  "landedBottomView",
  "landedRearView",
  "landedStarboardView",
  "landedAngledRearViewColored",
  "landedBottomViewColored",
  "landedRearViewColored",
  "landedStarboardViewColored",
] as const satisfies readonly (keyof ModelUpdateInput)[];

export const HOLO_FIELDS = [
  "holo",
  "extendedHolo",
  "landedHolo",
  "holoLite",
  "extendedHoloLite",
  "landedHoloLite",
  "holoTextured",
] as const satisfies readonly (keyof ModelUpdateInput)[];

export type ViewField = (typeof VIEW_FIELDS)[number];
export type HoloField = (typeof HOLO_FIELDS)[number];
export type FolderField = ViewField | HoloField;

export type FieldState = "flight" | "extended" | "landed";

export type FieldSection = {
  state: FieldState;
  holos: HoloField[];
  views: ViewField[][];
};

// Each row follows the ship page's cells: angled, plan, end-on, profile.
const VIEW_ROWS = [
  ["angledView", "topView", "frontView", "portView"],
  [
    "angledViewColored",
    "topViewColored",
    "frontViewColored",
    "portViewColored",
  ],
  ["angledRearView", "bottomView", "rearView", "starboardView"],
  [
    "angledRearViewColored",
    "bottomViewColored",
    "rearViewColored",
    "starboardViewColored",
  ],
] as const satisfies readonly (readonly ViewField[])[];

const inState = <T extends FolderField>(state: FieldState, field: T): T =>
  (state === "flight"
    ? field
    : `${state}${field.charAt(0).toUpperCase()}${field.slice(1)}`) as T;

export const FIELD_SECTIONS: readonly FieldSection[] = (
  ["flight", "extended", "landed"] as const
).map((state) => ({
  state,
  holos: (state === "flight"
    ? (["holo", "holoLite", "holoTextured"] as const)
    : (["holo", "holoLite"] as const)
  ).map((field) => inState(state, field)),
  views: VIEW_ROWS.map((row) => row.map((field) => inState(state, field))),
}));

// The order the fields are listed in, whatever order the folder was read in.
const FIELD_ORDER: readonly FolderField[] = FIELD_SECTIONS.flatMap(
  (section) => [...section.holos, ...section.views.flat()],
);

export const isHoloField = (field: FolderField): field is HoloField =>
  (HOLO_FIELDS as readonly string[]).includes(field);

export type MappedFile = {
  field: FolderField;
  filename: string;
};

// top.png, angled_colored.png, extended-side.png, landed-holo.glb,
// flight_top.png, flight_angled_rear.png, landed_holo_lite.glb. The separator,
// the case and a spelled-out "view" are all optional, so a folder named by hand
// lands where one named by a script does.
const VIEW_NAME =
  /^((?:extended|landed|flight)[-_ ]?)?(top|side|port|front|angled[-_ ]?rear|angled|bottom|rear|starboard)([-_ ]?view)?([-_ ]?colored)?$/i;
const HOLO_NAME =
  /^((?:extended|landed|flight)[-_ ]?)?holo(?:[-_ ]?(lite|textured))?$/i;

const VIEWPOINTS: Record<string, string> = {
  top: "top",
  side: "port",
  port: "port",
  front: "front",
  angled: "angled",
  angledrear: "angledRear",
  bottom: "bottom",
  rear: "rear",
  starboard: "starboard",
};

// The name alone is not enough: a Blender export drops holo.blend, holo.obj and
// holo.mtl beside the glTF, and every one of them answers to "holo".
const VIEW_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "gif"];
const HOLO_EXTENSIONS = ["gltf", "glb"];

// The regex accepts any of the three states, so the prefix that matched decides
// which family the file belongs to rather than a bare "is it prefixed at all".
// "flight" is the default state spelled out, and lands where no prefix does.
const prefixFor = (raw?: string): "extended" | "landed" | undefined => {
  const state = raw?.toLowerCase() ?? "";

  if (state.startsWith("landed")) {
    return "landed";
  }

  if (state.startsWith("extended")) {
    return "extended";
  }

  return undefined;
};

const capitalize = (word: string) =>
  `${word.charAt(0).toUpperCase()}${word.slice(1)}`;

export const fieldFor = (filename: string): FolderField | undefined => {
  // A folder picked through the file input carries its path in the name.
  const basename = filename.split("/").pop() ?? "";
  const stem = basename.replace(/\.[^.]+$/, "").trim();
  const extension = basename.slice(stem.length + 1).toLowerCase();

  const holo = HOLO_NAME.exec(stem);

  if (holo) {
    if (!HOLO_EXTENSIONS.includes(extension)) {
      return undefined;
    }

    const prefix = prefixFor(holo[1]);
    const variant = holo[2]?.toLowerCase();

    // Only the flying pose is exported painted.
    if (variant === "textured" && prefix) {
      return undefined;
    }

    const base = prefix ? `${prefix}Holo` : "holo";

    return (variant ? `${base}${capitalize(variant)}` : base) as HoloField;
  }

  const view = VIEW_NAME.exec(stem);

  if (!view || !VIEW_EXTENSIONS.includes(extension)) {
    return undefined;
  }

  const [, state, rawViewpoint, , colored] = view;
  const prefix = prefixFor(state);
  const viewpoint =
    VIEWPOINTS[rawViewpoint.toLowerCase().replace(/[-_ ]/g, "")];

  const base = prefix
    ? `${prefix}${capitalize(viewpoint)}View`
    : `${viewpoint}View`;

  return (colored ? `${base}Colored` : base) as ViewField;
};

export type MappedFolder<T> = {
  matched: (MappedFile & { item: T })[];
  ignored: string[];
};

// Two files claiming one field is a mistake in the folder, not something to
// resolve by guessing: the first one is taken and the other is reported.
export const mapFolderFiles = <T>(
  items: T[],
  filenameOf: (item: T) => string,
): MappedFolder<T> => {
  const matched: (MappedFile & { item: T })[] = [];
  const ignored: string[] = [];

  items.forEach((item) => {
    const filename = filenameOf(item);
    const field = fieldFor(filename);

    if (!field || matched.some((entry) => entry.field === field)) {
      ignored.push(filename.split("/").pop() ?? filename);
      return;
    }

    matched.push({ field, filename, item });
  });

  matched.sort(
    (left, right) =>
      FIELD_ORDER.indexOf(left.field) - FIELD_ORDER.indexOf(right.field),
  );

  return { matched, ignored };
};
