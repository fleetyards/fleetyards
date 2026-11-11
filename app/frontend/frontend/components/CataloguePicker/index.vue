<script lang="ts">
export default {
  name: "CataloguePicker",
};
</script>

<script lang="ts" setup>
import { keepPreviousData, useQuery } from "@tanstack/vue-query";
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import PickerCard, {
  type PickerCardBadge,
} from "@/shared/components/PickerCard/index.vue";
import CatalogueItemInfoBtn from "@/frontend/components/CatalogueItemPopover/InfoBtn/index.vue";
import CataloguePickerLayout from "@/frontend/components/CataloguePicker/Layout/index.vue";
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import {
  compareItemImage,
  compareItemImageFit,
} from "@/frontend/components/Compare/image";
import { useComponentCategoryLabel } from "@/frontend/composables/useComponentCategoryLabel";
import { useEquipmentPickerFilters } from "@/frontend/composables/useEquipmentPickerFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useReducedMotion } from "@/shared/composables/useReducedMotion";
import {
  componentCategoriesFilters,
  components as fetchComponents,
  equipment as fetchEquipment,
  equipmentTypesFilters,
  type Component,
  type ComponentQuery,
  type Equipment,
  type EquipmentQuery,
} from "@/services/fyApi";

export type CatalogueItem = Component | Equipment;

interface Props {
  kind: "Component" | "Equipment";
  // Narrows the catalogue for good, and takes the type filter's place.
  query?: ComponentQuery | EquipmentQuery;
  hideFilter?: boolean;
  // Equipment only: manufacturer, sub type, grade, size and weapon class
  // filters, offered within what `query` lets through.
  filterable?: boolean;
  isSelected?: (item: CatalogueItem) => boolean;
  isDisabled?: (item: CatalogueItem) => boolean;
  badgesOf?: (item: CatalogueItem) => PickerCardBadge[];
  cardTestPrefix: string;
}

const props = withDefaults(defineProps<Props>(), {
  query: undefined,
  hideFilter: false,
  filterable: false,
  isSelected: () => false,
  isDisabled: () => false,
  badgesOf: () => [],
});

const emit = defineEmits<{
  toggle: [item: CatalogueItem];
}>();

const slots = defineSlots<{
  summary?: () => unknown;
  notice?: () => unknown;
  details?: (scope: { item: CatalogueItem }) => unknown;
  tray?: () => unknown;
}>();

const PER_PAGE = "48";

const { t } = useI18n();

const categoryLabel = useComponentCategoryLabel();

const type = ref<string | undefined>();
const search = ref("");
const searchTerm = ref("");
const page = ref(1);
const records = ref<CatalogueItem[]>([]);

const filtered = computed(() => !props.query && !props.hideFilter);

const mobile = useMobile();

const { prefersReducedMotion } = useReducedMotion();

const equipmentFilters = useEquipmentPickerFilters(
  () => props.query as EquipmentQuery | undefined,
  () => props.filterable && props.kind === "Equipment",
);

const pickerFilters = computed(() =>
  props.filterable && props.kind === "Equipment"
    ? equipmentFilters.filters.value
    : [],
);

const primaryFilters = computed(() =>
  pickerFilters.value.filter((filter) => filter.primary),
);

const secondaryFilters = computed(() =>
  pickerFilters.value.filter((filter) => !filter.primary),
);

// On a phone every filter folds away behind the toggle, so the header leaves
// room for the grid under it.
const togglesFilters = computed(() =>
  mobile.value ? !!pickerFilters.value.length : !!secondaryFilters.value.length,
);

const moreFiltersOpen = ref(false);

// Per instance: the Teleport finds its target with a document-wide lookup, and
// a closing picker can still be in the DOM while the next one mounts.
const foldedFiltersId = `catalogue-picker-folded-${useId()}`;

const folded = computed(() =>
  mobile.value ? pickerFilters.value : secondaryFilters.value,
);

const moreFiltersCount = computed(
  () =>
    folded.value.filter((filter) => equipmentFilters.isPicked(filter.key))
      .length,
);

const moreFiltersLabel = computed(() =>
  mobile.value
    ? t("labels.filter")
    : t("labels.logistics.itemPicker.moreFilters"),
);

// The aria-label replaces the button's content as its name, badge included, so
// the count has to be spoken from here.
const moreFiltersAriaLabel = computed(() =>
  moreFiltersCount.value
    ? `${moreFiltersLabel.value} (${moreFiltersCount.value})`
    : moreFiltersLabel.value,
);

const filtersActive = computed(
  () => !!Object.keys(equipmentFilters.query.value).length,
);

const { data: typeOptions } = useQuery({
  queryKey: ["catalogue-picker-types", props.kind],
  queryFn: () =>
    props.kind === "Component"
      ? componentCategoriesFilters()
      : equipmentTypesFilters(),
  enabled: computed(() => !props.query),
  refetchOnWindowFocus: false,
});

const activeQuery = computed(() => {
  if (props.query) return { ...props.query, ...equipmentFilters.query.value };
  if (!type.value) return {};

  return props.kind === "Component"
    ? { categoryIn: [type.value] }
    : { equipmentTypeIn: [type.value] };
});

interface PickerPage {
  items: CatalogueItem[];
  currentPage: number;
  totalPages: number;
  totalCount: number;
}

const fetchPage = async (): Promise<PickerPage> => {
  const params = { page: String(page.value), perPage: PER_PAGE };
  const term = searchTerm.value || undefined;

  const response =
    props.kind === "Component"
      ? await fetchComponents({
          ...params,
          q: {
            currentVersion: true,
            hiddenEq: false,
            searchNameCont: term,
            ...(activeQuery.value as ComponentQuery),
          },
        })
      : await fetchEquipment({
          ...params,
          q: {
            currentVersion: true,
            nameOrSlugCont: term,
            ...(activeQuery.value as EquipmentQuery),
          },
        });

  const pagination = response.meta?.pagination;

  return {
    items: response.items,
    currentPage: pagination?.currentPage ?? 1,
    totalPages: pagination?.totalPages ?? 1,
    totalCount: pagination?.totalCount ?? response.items.length,
  };
};

const { data, isFetching, isPlaceholderData } = useQuery({
  queryKey: computed(() => [
    "catalogue-picker",
    props.kind,
    activeQuery.value,
    searchTerm.value,
    page.value,
  ]),
  queryFn: fetchPage,
  refetchOnWindowFocus: false,
  placeholderData: keepPreviousData,
});

const totalPages = ref(1);
const totalCount = ref(0);

// The page that arrived says whether it extends the grid or replaces it, so a
// stale page 2 cannot land on a grid a new search already reset.
watch(
  [data, isPlaceholderData],
  ([response, placeholder]) => {
    if (!response || placeholder) return;

    totalPages.value = response.totalPages;
    totalCount.value = response.totalCount;

    if (response.currentPage <= 1) {
      records.value = response.items;
      return;
    }

    const known = new Set(records.value.map((item) => item.id));

    records.value = [
      ...records.value,
      ...response.items.filter((item) => !known.has(item.id)),
    ];
  },
  { immediate: true },
);

const hasMore = computed(
  () => !isPlaceholderData.value && page.value < totalPages.value,
);

// A next page on its way reads as a placeholder too, which is no reason to take
// the button away: it shows the wait, and the grid keeps its height.
const loadingMore = computed(() => isPlaceholderData.value && page.value > 1);

const initialLoading = computed(
  () => isFetching.value && !records.value.length,
);

const refreshing = computed(
  () => isFetching.value && page.value === 1 && !!records.value.length,
);

const applySearch = debounce((value: string) => {
  searchTerm.value = value;
  page.value = 1;
}, 300);

watch(search, (value) => {
  applySearch(value);
});

watch([type, equipmentFilters.query], () => {
  page.value = 1;
});

onUnmounted(() => {
  applySearch.cancel();
});

const loadMore = () => {
  if (!hasMore.value || isFetching.value) return;

  page.value += 1;
};

const imageOf = (item: CatalogueItem) => {
  const image = compareItemImage(item);

  return image?.mediumUrl || image?.smallUrl || undefined;
};

const subtitleOf = (item: CatalogueItem) => {
  const kindLabel =
    props.kind === "Component"
      ? (item as Component).category
        ? categoryLabel((item as Component).category as string)
        : undefined
      : ((item as Equipment).itemTypeLabel ??
        (item as Equipment).equipmentTypeLabel);

  return [item.manufacturer?.name, kindLabel].filter(Boolean).join(" · ");
};

const resultsLabel = computed(() =>
  props.kind === "Component"
    ? t("labels.compare.componentCount", { count: totalCount.value })
    : t("labels.compare.equipmentCount", { count: totalCount.value }),
);
</script>

<template>
  <CataloguePickerLayout
    v-model:search="search"
    :count-label="resultsLabel"
    :loading="initialLoading"
    :empty="!isFetching && !records.length"
    :refreshing="refreshing"
  >
    <template v-if="filtered" #filters>
      <BaseSelect
        v-model="type"
        class="catalogue-picker__filter"
        name="catalogue-picker-type"
        :options="typeOptions || []"
        :label="
          kind === 'Component'
            ? t('labels.component.category')
            : t('labels.filters.equipment.equipmentType')
        "
        no-label
        :searchable="true"
        :nullable="true"
      />
    </template>
    <template v-else-if="pickerFilters.length" #filters>
      <Teleport :to="`#${foldedFiltersId}`" :disabled="!mobile" defer>
        <BaseSelect
          v-for="filter in primaryFilters"
          :key="filter.key"
          v-model="equipmentFilters.picks.value[filter.key]"
          class="catalogue-picker__filter"
          :name="`catalogue-picker-${filter.key}`"
          :options="filter.options"
          :label="filter.label"
          no-label
          multiple
          searchable
        />
      </Teleport>

      <Btn
        v-if="togglesFilters"
        class="catalogue-picker__more-filters"
        :active="moreFiltersOpen"
        :aria-expanded="moreFiltersOpen"
        :aria-controls="`${foldedFiltersId}-panel`"
        v-tooltip="moreFiltersLabel"
        :aria-label="moreFiltersAriaLabel"
        data-test="catalogue-picker-more-filters"
        @click="moreFiltersOpen = !moreFiltersOpen"
      >
        <i v-if="moreFiltersCount" class="fa-solid fa-filter" />
        <i v-else class="fa-regular fa-filter" />
        <span v-if="moreFiltersCount" class="catalogue-picker__filter-count">
          {{ moreFiltersCount }}
        </span>
      </Btn>
    </template>
    <template v-if="pickerFilters.length" #moreFilters>
      <Collapsed
        :id="`${foldedFiltersId}-panel`"
        :visible="moreFiltersOpen"
        :duration="prefersReducedMotion ? 1 : 200"
      >
        <div class="catalogue-picker__more-toolbar">
          <div :id="foldedFiltersId" class="catalogue-picker__folded" />

          <BaseSelect
            v-for="filter in secondaryFilters"
            :key="filter.key"
            v-model="equipmentFilters.picks.value[filter.key]"
            class="catalogue-picker__filter"
            :name="`catalogue-picker-${filter.key}`"
            :options="filter.options"
            :label="filter.label"
            no-label
            multiple
          />
        </div>
      </Collapsed>
    </template>
    <template v-if="slots.summary || filtersActive" #summary>
      <slot name="summary" />
      <Btn
        v-if="filtersActive"
        class="catalogue-picker__reset"
        :variant="BtnVariantsEnum.BARE"
        :size="BtnSizesEnum.XS"
        data-test="catalogue-picker-reset-filters"
        @click="equipmentFilters.reset"
      >
        {{ t("labels.logistics.itemPicker.resetFilters") }}
      </Btn>
    </template>
    <template v-if="slots.notice" #notice>
      <slot name="notice" />
    </template>

    <PickerCard
      v-for="item in records"
      :key="item.id"
      :name="item.name"
      :subtitle="subtitleOf(item)"
      :image="imageOf(item)"
      :image-fit="compareItemImageFit(item)"
      :badges="badgesOf(item)"
      :selected="isSelected(item)"
      :disabled="isDisabled(item)"
      :data-test="`${cardTestPrefix}-${item.slug}`"
      @toggle="emit('toggle', item)"
    >
      <template #placeholder>
        <HardpointCategoryIcon
          v-if="kind === 'Component'"
          :category="(item as Component).category"
        />
        <EquipmentIcon v-else :equipment="item as Equipment" />
      </template>
      <template #info>
        <CatalogueItemInfoBtn
          :item="{ type: kind, slug: item.slug, name: item.name }"
          :record="item"
        />
      </template>
      <slot name="details" :item="item" />
    </PickerCard>

    <template v-if="hasMore || loadingMore" #more>
      <Btn
        :loading="isFetching"
        :variant="BtnVariantsEnum.BARE"
        data-test="catalogue-picker-more"
        @click="loadMore"
      >
        {{ t("actions.loadMore") }}
      </Btn>
    </template>
    <template v-if="slots.tray" #tray>
      <slot name="tray" />
    </template>
  </CataloguePickerLayout>
</template>

<style lang="scss" scoped>
.catalogue-picker__filter {
  flex: 1;
  min-width: 200px;
}

/* Matched to the fields it stands next to rather than sized by its own text, so
   the toolbar reads as one row. */
.catalogue-picker__more-filters {
  align-self: stretch;
}

.catalogue-picker__filter-count {
  color: var(--color-gold, #d4af37);
  font-weight: 600;
  font-variant-numeric: tabular-nums;
}

/* Inside the element Collapsed animates, not on it: it holds the animated
   element's padding at zero until the end, and the row would jump down. */
.catalogue-picker__more-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 0.75rem;
  padding-top: 12px;
}

/* Lets the moved fields wrap with the rest of the row they land in. */
.catalogue-picker__folded {
  display: contents;
}

.catalogue-picker__reset {
  margin-left: auto;
}
</style>
