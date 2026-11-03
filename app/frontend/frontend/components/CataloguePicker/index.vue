<script lang="ts">
export default {
  name: "CataloguePicker",
};
</script>

<script lang="ts" setup>
import { keepPreviousData, useQuery } from "@tanstack/vue-query";
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import PickerCard, {
  type PickerCardBadge,
} from "@/shared/components/PickerCard/index.vue";
import CataloguePickerLayout from "@/frontend/components/CataloguePicker/Layout/index.vue";
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import {
  compareItemImage,
  compareItemImageFit,
} from "@/frontend/components/Compare/image";
import { useComponentCategoryLabel } from "@/frontend/composables/useComponentCategoryLabel";
import { useI18n } from "@/shared/composables/useI18n";
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

type Props = {
  kind: "Component" | "Equipment";
  // Narrows the catalogue for good, and takes the type filter's place.
  query?: ComponentQuery | EquipmentQuery;
  hideFilter?: boolean;
  isSelected?: (item: CatalogueItem) => boolean;
  isDisabled?: (item: CatalogueItem) => boolean;
  badgesOf?: (item: CatalogueItem) => PickerCardBadge[];
  cardTestPrefix: string;
};

const props = withDefaults(defineProps<Props>(), {
  query: undefined,
  hideFilter: false,
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
  if (props.query) return props.query;
  if (!type.value) return {};

  return props.kind === "Component"
    ? { categoryIn: [type.value] }
    : { equipmentTypeIn: [type.value] };
});

type PickerPage = {
  items: CatalogueItem[];
  currentPage: number;
  totalPages: number;
  totalCount: number;
};

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

watch(type, () => {
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
    <template v-if="slots.summary" #summary>
      <slot name="summary" />
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
      <slot name="details" :item="item" />
    </PickerCard>

    <template v-if="hasMore" #more>
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

<style scoped>
@reference "../../../entrypoints/tailwind.css";

.catalogue-picker__filter {
  @apply min-w-[200px] flex-1;
}
</style>
