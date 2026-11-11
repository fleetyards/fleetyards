import { useI18n } from "@/shared/composables/useI18n";
import {
  type EquipmentFacetFilterQuery,
  type EquipmentQuery,
  type FilterOption,
  useEquipmentGradesFilters,
  useEquipmentManufacturersFilters,
  useEquipmentSizesFilters,
  useEquipmentSubTypesFilters,
  useEquipmentWeaponClassesFilters,
} from "@/services/fyApi";

export type EquipmentPickerFilterKey =
  "manufacturerSlugIn" | "subTypeIn" | "gradeIn" | "sizeIn" | "weaponClassIn";

export interface EquipmentPickerFilter {
  key: EquipmentPickerFilterKey;
  label: string;
  options: FilterOption[];
  // Shown beside the search; the rest wait behind the toggle.
  primary: boolean;
}

const emptyPicks = (): Record<EquipmentPickerFilterKey, string[]> => ({
  manufacturerSlugIn: [],
  subTypeIn: [],
  gradeIn: [],
  sizeIn: [],
  weaponClassIn: [],
});

// The options are drawn from the items the pinned query lets through, so a pick
// can only narrow it: a sub type or size it pins is never widened.
export const useEquipmentPickerFilters = (
  pinned: () => EquipmentQuery | undefined,
  enabled: () => boolean,
) => {
  const { t } = useI18n();

  const picks =
    ref<Record<EquipmentPickerFilterKey, string[] | undefined>>(emptyPicks());

  const facetParams = computed(() => {
    const query = pinned() ?? {};
    const q: EquipmentFacetFilterQuery = {
      equipmentTypeIn: query.equipmentTypeIn,
      subTypeIn: query.subTypeIn,
      slotIn: query.slotIn,
      sizeIn: query.sizeIn,
    };

    return { q };
  });

  const options = {
    query: {
      enabled: computed(enabled),
      refetchOnWindowFocus: false,
    },
  };

  const { data: manufacturers } = useEquipmentManufacturersFilters(
    facetParams,
    options,
  );
  const { data: subTypes } = useEquipmentSubTypesFilters(facetParams, options);
  const { data: grades } = useEquipmentGradesFilters(facetParams, options);
  const { data: sizes } = useEquipmentSizesFilters(facetParams, options);
  const { data: weaponClasses } = useEquipmentWeaponClassesFilters(
    facetParams,
    options,
  );

  // A filter with a single option would only ever repeat the list it sits on.
  const filters = computed<EquipmentPickerFilter[]>(() =>
    [
      {
        key: "manufacturerSlugIn" as const,
        label: t("labels.filters.manufacturer"),
        options: manufacturers.value ?? [],
        primary: true,
      },
      {
        key: "subTypeIn" as const,
        label: t("labels.filters.equipment.subType"),
        options: subTypes.value ?? [],
        primary: true,
      },
      {
        key: "gradeIn" as const,
        label: t("labels.filters.equipment.grade"),
        options: grades.value ?? [],
        primary: false,
      },
      {
        key: "sizeIn" as const,
        label: t("labels.filters.equipment.size"),
        options: sizes.value ?? [],
        primary: false,
      },
      {
        key: "weaponClassIn" as const,
        label: t("labels.filters.equipment.weaponClass"),
        options: weaponClasses.value ?? [],
        primary: false,
      },
    ].filter((filter) => filter.options.length > 1),
  );

  const query = computed<EquipmentQuery>(() => {
    const picked: EquipmentQuery = {};

    for (const [key, values] of Object.entries(picks.value)) {
      if (values?.length) {
        picked[key as EquipmentPickerFilterKey] = values;
      }
    }

    return picked;
  });

  const isPicked = (key: EquipmentPickerFilterKey) =>
    !!picks.value[key]?.length;

  const reset = () => {
    picks.value = emptyPicks();
  };

  return { picks, filters, query, isPicked, reset };
};
