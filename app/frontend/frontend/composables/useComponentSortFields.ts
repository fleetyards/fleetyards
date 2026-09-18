import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import {
  METRIC_FIELDS,
  metricValue,
} from "@/frontend/components/Components/metricFields";
import { type Component } from "@/services/fyApi";

/**
 * The sorts the catalogue offers above its rows.
 *
 * A row list has no column headings, so the sort line is the whole control
 * rather than a second way to reach one -- which is why it lives beside the
 * list rather than inside it: `FilteredList` renders its results slot only once
 * the first page has arrived, and a control that disappears while the thing it
 * controls is loading is the wrong way round.
 */
export const useComponentSortFields = (
  components: MaybeRefOrGetter<Component[]>,
) => {
  const { t } = useI18n();

  const route = useRoute();

  // The metric the list is ordered by right now, if any. `q[s]` carries one
  // sort as "<field> <direction>".
  const activeSort = computed(
    () => String(route.query.s || "").split(" ")[0] || undefined,
  );

  return computed<BaseTableCol<Component>[]>(() => {
    const records = toValue(components);

    return [
      { name: "name", label: t("labels.hardpoint.name"), sortable: true },
      {
        name: "manufacturerName",
        label: t("labels.filters.manufacturer"),
        sortable: true,
      },
      {
        name: "category",
        label: t("labels.component.category"),
        sortable: true,
      },
      {
        name: "componentSubType",
        label: t("labels.component.subType"),
        sortable: true,
      },
      // `sizeOrder` rather than `size`, which is a string ransacker -- ordering
      // it puts 10 and 12 ahead of 2.
      {
        name: "size",
        label: t("labels.hardpoint.size"),
        attributeKey: "sizeOrder",
        sortable: true,
      },
      { name: "grade", label: t("labels.component.grade"), sortable: true },

      // Only the metrics the rows on screen actually carry. Unfiltered the list
      // is mostly paints and none appear; narrowed to shield generators, HP and
      // Regen join the line. Driven by the records rather than by the chosen
      // category, so it needs no map from one to the other and still works for
      // a search that happens to land on one kind of part.
      // Or the one the list is ordered by. Derived from the records alone, a
      // metric sort vanished the moment a page happened to hold no row carrying
      // it -- the list stayed ordered by a setting with no control left to see
      // or undo it.
      ...METRIC_FIELDS.filter(
        (metric) =>
          metric.sort === activeSort.value ||
          records.some((record) => metricValue(record, metric.field) != null),
      ).map((metric) => ({
        name: metric.field,
        label: t(metric.labelKey),
        attributeKey: metric.sort,
        sortable: true,
      })),
    ];
  });
};
