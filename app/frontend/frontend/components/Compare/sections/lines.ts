import { toValue, type MaybeRefOrGetter } from "vue";
import { useHardpointStatsFor } from "@/frontend/composables/useHardpointStats";
import { rowPresentation } from "@/frontend/components/Models/Hardpoints/rowPresentation";
import {
  hasRowData,
  type CompareLine,
  type CompareLinePart,
  type CompareTableRow,
} from "@/frontend/components/Compare/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";

// What sits inside a part and rides along on its line instead of a line of its
// own: a scraper on a salvage head, a module in a mining laser.
const MODIFIER_CATEGORIES: (HardpointCategoryEnum | undefined)[] = [
  HardpointCategoryEnum.SALVAGE_MODULES,
  HardpointCategoryEnum.MINING_MODULES,
];

// What carries a part and names where it sits. A gimbal is left out: nearly
// every gun has one, and naming it on each line says nothing.
const CARRIER_CATEGORIES: (HardpointCategoryEnum | undefined)[] = [
  HardpointCategoryEnum.TURRET,
  HardpointCategoryEnum.MISSILE_RACKS,
  HardpointCategoryEnum.BOMBCOMPARTMENTS,
];

const humanize = (name?: string) =>
  (name || "")
    .replace(/^hardpoint_/, "")
    .split("_")
    .join(" ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
    .trim();

const contents = (hardpoint: Hardpoint): Hardpoint[] =>
  hardpoint.hardpoints?.length
    ? hardpoint.hardpoints
    : hardpoint.component?.hardpoints || [];

// One line per kind of fitted part, so a cell stays a few lines tall however
// deep the ship nests it: a Moth's salvage head sits three levels down a manned
// turret, and the ship page's card for it runs a screen tall.
export const useLoadoutLines = (
  models: MaybeRefOrGetter<Model[]>,
  hardpointsFor: (model: Model) => Hardpoint[],
) => {
  const { t, toNumber } = useI18n();
  const statsFor = useHardpointStatsFor();

  const figureOf = (hardpoint: Hardpoint) => {
    const presented = rowPresentation(hardpoint.category).headline?.(
      hardpoint,
      t,
      toNumber,
    );

    if (presented) {
      return presented;
    }

    const primary = statsFor(hardpoint).find((stat) => stat.primary);

    return primary
      ? { value: primary.value, unit: primary.label, raw: primary.raw }
      : undefined;
  };

  const nameOf = (hardpoint: Hardpoint) =>
    rowPresentation(hardpoint.category).label?.(hardpoint, t) ||
    hardpoint.component?.name ||
    humanize(hardpoint.component?.scKey || hardpoint.name);

  // Keyed on the part, not on its label: thrusters are labelled by their kind
  // alone, so two of one kind but different thrust would read as one line.
  const partOf = (hardpoint: Hardpoint): CompareLinePart => {
    const size = hardpoint.component?.size;
    const figure = figureOf(hardpoint);

    return {
      key: [hardpoint.component?.name || hardpoint.component?.id, size].join(
        "|",
      ),
      size: size ? `S${size}` : undefined,
      name: nameOf(hardpoint),
      figure: figure && { value: figure.value, unit: figure.unit },
      raw: figure?.raw,
      hardpoint,
    };
  };

  const modulesOf = (hardpoint: Hardpoint) =>
    contents(hardpoint)
      .filter(
        (child) =>
          child.component && MODIFIER_CATEGORIES.includes(child.category),
      )
      .map(partOf);

  const carrierName = (hardpoint: Hardpoint) => {
    // An arm with no name of its own is named after its port, less the side:
    // a Salvation's two arms are one kind of place, and naming them apart
    // would keep its identical heads on two lines.
    if (hardpoint.component?.type === "ToolArm") {
      return (
        hardpoint.component.name ||
        humanize(hardpoint.name.replace(/_(left|right|front|rear)\b/gi, ""))
      );
    }

    return CARRIER_CATEGORIES.includes(hardpoint.category)
      ? nameOf(hardpoint)
      : undefined;
  };

  const linesFor = (
    hardpoints: Hardpoint[],
    categories: HardpointCategoryEnum[],
  ): CompareLine[] => {
    const lines = new Map<string, CompareLine>();

    const walk = (list: Hardpoint[], context?: string) => {
      for (const hardpoint of list) {
        const isPart =
          !!hardpoint.component &&
          !!hardpoint.category &&
          categories.includes(hardpoint.category);

        if (isPart) {
          const part = partOf(hardpoint);
          const parts = modulesOf(hardpoint);
          const key = [
            part.key,
            context,
            parts.map((entry) => entry.key).join("+"),
          ].join("|");
          const existing = lines.get(key);

          if (existing) {
            existing.quantity += 1;
          } else {
            lines.set(key, { ...part, key, quantity: 1, context, parts });
          }
        }

        walk(contents(hardpoint), carrierName(hardpoint) ?? context);
      }
    };

    walk(hardpoints);

    return [...lines.values()];
  };

  const lineRow = (
    key: string,
    label: string,
    categories: HardpointCategoryEnum[],
  ): CompareTableRow => ({
    kind: "lines",
    key,
    label,
    cells: toValue(models).map((model) => ({
      key: model.slug,
      lines: linesFor(hardpointsFor(model), categories),
    })),
  });

  // The rows a band lists, each by the categories it gathers, dropped where no
  // compared ship fits anything.
  const lineRows = (
    rows: { key: string; label: string; categories: HardpointCategoryEnum[] }[],
  ) =>
    rows
      .map((row) => lineRow(row.key, row.label, row.categories))
      .filter((row) => hasRowData([row]));

  return { lineRows };
};
