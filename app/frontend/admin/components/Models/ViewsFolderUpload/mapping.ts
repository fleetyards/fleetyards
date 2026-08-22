import { type ModelUpdateInput } from "@/services/fyAdminApi";

export const VIEW_FIELDS = [
  "topView",
  "sideView",
  "frontView",
  "angledView",
  "topViewColored",
  "sideViewColored",
  "frontViewColored",
  "angledViewColored",
  "extendedTopView",
  "extendedSideView",
  "extendedFrontView",
  "extendedAngledView",
  "extendedTopViewColored",
  "extendedSideViewColored",
  "extendedFrontViewColored",
  "extendedAngledViewColored",
] as const satisfies readonly (keyof ModelUpdateInput)[];

export const HOLO_FIELDS = [
  "holo",
  "extendedHolo",
] as const satisfies readonly (keyof ModelUpdateInput)[];

export type ViewField = (typeof VIEW_FIELDS)[number];
export type HoloField = (typeof HOLO_FIELDS)[number];
export type FolderField = ViewField | HoloField;

// The order the fields are listed in, whatever order the folder was read in.
const FIELD_ORDER: readonly FolderField[] = [...VIEW_FIELDS, ...HOLO_FIELDS];

export const isHoloField = (field: FolderField): field is HoloField =>
  (HOLO_FIELDS as readonly string[]).includes(field);

export type MappedFile = {
  field: FolderField;
  filename: string;
};

// top.png, angled_colored.png, extended-side.png, holo.gltf. The separator, the
// case and a spelled-out "view" are all optional, so a folder named by hand
// lands where one named by a script does.
const VIEW_NAME =
  /^(extended[-_ ]?)?(top|side|front|angled)([-_ ]?view)?([-_ ]?colored)?$/i;
const HOLO_NAME = /^(extended[-_ ]?)?holo$/i;

// The name alone is not enough: a Blender export drops holo.blend, holo.obj and
// holo.mtl beside the glTF, and every one of them answers to "holo".
const VIEW_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "gif"];
const HOLO_EXTENSIONS = ["gltf", "glb"];

const capitalize = (word: string) =>
  `${word.charAt(0).toUpperCase()}${word.slice(1).toLowerCase()}`;

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

    return holo[1] ? "extendedHolo" : "holo";
  }

  const view = VIEW_NAME.exec(stem);

  if (!view || !VIEW_EXTENSIONS.includes(extension)) {
    return undefined;
  }

  const [, extended, viewpoint, , colored] = view;

  const base = extended
    ? `extended${capitalize(viewpoint)}View`
    : `${viewpoint.toLowerCase()}View`;

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
