import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { useCompareFormat } from "@/frontend/components/Compare/format";
import {
  hasRowData,
  valueRows,
  type CompareMetric,
  type CompareSection,
  type CompareTableRow,
} from "@/frontend/components/Compare/types";
import { statDirection } from "@/frontend/components/Compare/sections/statDirections";
import { hardpointCategoryFor } from "@/frontend/composables/useComponentStats";
import { DAMAGE_TYPES } from "@/frontend/composables/useComponentDurability";
import {
  useHardpointStatsFor,
  type HardpointStat,
} from "@/frontend/composables/useHardpointStats";
import { useI18n } from "@/shared/composables/useI18n";
import type { Component, Hardpoint } from "@/services/fyApi";

const statKey = (stat: HardpointStat) => stat.key ?? stat.label;

export const useComponentSections = (
  components: MaybeRefOrGetter<Component[]>,
) => {
  const { t, tExists } = useI18n();
  const { number, percent, text } = useCompareFormat();
  const statsFor = useHardpointStatsFor();

  const subjects = () =>
    toValue(components).map((component) => ({
      key: component.slug,
      subject: component,
    }));

  const section = (
    id: string,
    title: string,
    rows: CompareTableRow[],
  ): CompareSection | undefined => {
    // A row no item has a figure for is a row of dashes.
    const filled = rows.filter((row) => hasRowData([row]));

    return filled.length ? { id, title, rows: filled } : undefined;
  };

  const categoryLabel = (category?: string | null) => {
    if (!category) return undefined;

    const path = `labels.hardpoint.categories.${category}`;

    return tExists(path) ? t(path) : category;
  };

  const identityMetrics: CompareMetric<Component>[] = [
    {
      key: "manufacturer",
      label: t("model.manufacturer"),
      value: (component) => text(component.manufacturer?.name),
    },
    {
      key: "category",
      label: t("labels.component.category"),
      value: (component) => categoryLabel(component.category),
    },
    {
      key: "sub-type",
      label: t("labels.component.subType"),
      value: (component) => text(component.subType),
    },
    {
      key: "size",
      label: t("labels.hardpoint.size"),
      value: (component) => text(component.size),
    },
    {
      key: "grade",
      label: t("labels.component.grade"),
      value: (component) => text(component.gradeLabel ?? component.grade),
    },
    {
      key: "item-class",
      label: t("labels.component.itemClass"),
      value: (component) => text(component.itemClassLabel),
    },
  ];

  const identity = computed(() =>
    section(
      "identity",
      t("headlines.component.identity"),
      valueRows(identityMetrics, subjects()),
    ),
  );

  // The figures every component page shows, read through the same builder so a
  // compare cell and the detail page never disagree. Worked out once per item
  // rather than once per row.
  const stats = computed(() => {
    const byItem = new Map<string, HardpointStat[]>();

    toValue(components).forEach((component) => {
      const category = hardpointCategoryFor(component.category);

      byItem.set(
        component.slug,
        category ? statsFor({ category, component } as Hardpoint) : [],
      );
    });

    return byItem;
  });

  // One row per figure any of the items has, in the order the first item to
  // carry it lists it, so a set of quantum drives reads like a drive's own page.
  const statRows = (group?: string): CompareTableRow[] => {
    const list = toValue(components);
    const order: string[] = [];
    const labels = new Map<string, string>();

    list.forEach((component) => {
      stats.value.get(component.slug)?.forEach((stat) => {
        if (stat.group !== group) return;

        const key = statKey(stat);
        if (labels.has(key)) return;

        labels.set(key, stat.label);
        order.push(key);
      });
    });

    return order.map((key) => ({
      kind: "value" as const,
      key: `stat-${key}`,
      label: labels.get(key) ?? key,
      direction: statDirection(key),
      cells: list.map((component) => {
        const stat = stats.value
          .get(component.slug)
          ?.find((entry) => entry.group === group && statKey(entry) === key);

        return {
          key: component.slug,
          value: stat?.value || undefined,
          raw: stat?.raw,
        };
      }),
    }));
  };

  const metrics = computed(() =>
    section("metrics", t("headlines.component.metrics"), statRows()),
  );

  // A mode of the item -- a quantum drive's spline jump -- gets a section of its
  // own, as it gets a card of its own on the detail page.
  const modes = computed(() => {
    const groups = new Set<string>();

    stats.value.forEach((list) =>
      list.forEach((stat) => {
        if (stat.group) groups.add(stat.group);
      }),
    );

    return [...groups]
      .map((group) =>
        section(
          `mode-${group}`,
          t(`headlines.component.${group}`),
          statRows(group),
        ),
      )
      .filter((entry): entry is CompareSection => !!entry);
  });

  // A resistance is the share of a hit the item takes, so less is better.
  const durabilityMetrics: CompareMetric<Component>[] = [
    {
      key: "health",
      label: t("labels.component.durability.health"),
      unit: "HP",
      direction: "higher",
      raw: (component) => component.durability?.health ?? undefined,
      value: (component) => number(component.durability?.health, "integer"),
    },
    {
      key: "mass",
      label: t("labels.component.durability.mass"),
      unit: "kg",
      raw: (component) => component.durability?.mass ?? undefined,
      value: (component) => number(component.durability?.mass, "integer"),
    },
    ...DAMAGE_TYPES.map((type): CompareMetric<Component> => ({
      key: `damage-${type}`,
      label: t(`labels.component.durability.${type}`),
      direction: "lower",
      raw: (component) => component.durability?.resistances?.[type],
      value: (component) => percent(component.durability?.resistances?.[type]),
      // Every type takes the full hit unless the item says otherwise, so a
      // row where none differs says nothing.
      visible: (list) =>
        list.some((component) => {
          const multiplier = component.durability?.resistances?.[type];

          return typeof multiplier === "number" && multiplier !== 1;
        }),
    })),
  ];

  const durability = computed(() =>
    section(
      "durability",
      t("headlines.component.durability"),
      valueRows(durabilityMetrics, subjects()),
    ),
  );

  const sections = computed<CompareSection[]>(() =>
    [identity.value, metrics.value, ...modes.value, durability.value].filter(
      (entry): entry is CompareSection => !!entry,
    ),
  );

  return { sections };
};
