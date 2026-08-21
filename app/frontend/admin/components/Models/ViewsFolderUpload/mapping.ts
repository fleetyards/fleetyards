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

export type ViewField = (typeof VIEW_FIELDS)[number];

export type MappedView = {
  field: ViewField;
  filename: string;
};

// top.png, angled_colored.png, extended-side.png. The separator, the case and a
// spelled-out "view" are all optional so a folder named by hand lands in the
// same place as one named by a script.
const FILENAME =
  /^(extended[-_ ]?)?(top|side|front|angled)([-_ ]?view)?([-_ ]?colored)?$/i;

const capitalize = (word: string) =>
  `${word.charAt(0).toUpperCase()}${word.slice(1).toLowerCase()}`;

export const viewFieldFor = (filename: string): ViewField | undefined => {
  // A folder picked through the file input carries its path in the name.
  const stem = (filename.split("/").pop() ?? "").replace(/\.[^.]+$/, "").trim();

  const match = FILENAME.exec(stem);

  if (!match) {
    return undefined;
  }

  const [, extended, viewpoint, , colored] = match;

  const base = extended
    ? `extended${capitalize(viewpoint)}View`
    : `${viewpoint.toLowerCase()}View`;

  return (colored ? `${base}Colored` : base) as ViewField;
};

export type MappedFolder<T> = {
  matched: (MappedView & { item: T })[];
  ignored: string[];
};

// Two files claiming one view is a mistake in the folder, not something to
// resolve by guessing: the first one is taken and the other is reported.
export const mapViewFiles = <T>(
  items: T[],
  filenameOf: (item: T) => string,
): MappedFolder<T> => {
  const matched: (MappedView & { item: T })[] = [];
  const ignored: string[] = [];

  items.forEach((item) => {
    const filename = filenameOf(item);
    const field = viewFieldFor(filename);

    if (!field || matched.some((view) => view.field === field)) {
      ignored.push(filename.split("/").pop() ?? filename);
      return;
    }

    matched.push({ field, filename, item });
  });

  return { matched, ignored };
};
