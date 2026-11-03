<script lang="ts">
export default {
  name: "CompareCataloguePickerModal",
};
</script>

<script lang="ts" setup>
import { keepPreviousData, useQuery } from "@tanstack/vue-query";
import debounce from "lodash.debounce";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Loader from "@/shared/components/Loader/index.vue";
import PickerCard from "@/shared/components/PickerCard/index.vue";
import EquipmentIcon from "@/frontend/components/Equipment/Icon/index.vue";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import { compareItemImage } from "@/frontend/components/Compare/image";
import {
  componentCompareCategory,
  equipmentCompareCategory,
  type CompareCategory,
} from "@/frontend/components/Compare/category";
import { useCompareSet } from "@/frontend/composables/useCompareSet";
import { useComponentCategoryLabel } from "@/frontend/composables/useComponentCategoryLabel";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
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

type Props = {
  kind: "Component" | "Equipment";
  queryKey: string;
  // The category the set already holds. Absent for an empty set, whose first
  // pick decides it.
  lock?: CompareCategory<ComponentQuery | EquipmentQuery>;
};

const props = withDefaults(defineProps<Props>(), {
  lock: undefined,
});

type Item = Component | Equipment;

const PER_PAGE = "48";

const { t } = useI18n();

const comlink = useComlink();

const mobile = useMobile();

const categoryLabel = useComponentCategoryLabel();

const { slugs: compared, replace, flush } = useCompareSet(props.queryKey);

// Read once, at open: the picker adds to the set the page had when it opened.
const taken = new Set(compared.value);

const selection = ref<Item[]>([]);

const categoryOf = (item: Item) =>
  props.kind === "Component"
    ? componentCompareCategory(item as Component, categoryLabel)
    : equipmentCompareCategory(item as Equipment);

// The set's category, or the first pick's when the set is empty: a comparison
// holds one category, so the rest of the catalogue goes out of reach with it.
// Only the set's narrows the query; a pick's greys the other cards out instead,
// so picking or dropping the first one does not reload the grid under the
// reader.
const lock = computed(
  () =>
    props.lock ??
    (selection.value[0] ? categoryOf(selection.value[0]) : undefined),
);

const type = ref<string | undefined>();
const search = ref("");
const searchTerm = ref("");
const page = ref(1);
const records = ref<Item[]>([]);

const { data: typeOptions } = useQuery({
  queryKey: ["compare-picker-types", props.kind],
  queryFn: () =>
    props.kind === "Component"
      ? componentCategoriesFilters()
      : equipmentTypesFilters(),
  enabled: computed(() => !props.lock),
  refetchOnWindowFocus: false,
});

const query = computed(() => {
  if (props.lock) return props.lock.query;
  if (!type.value) return {};

  return props.kind === "Component"
    ? { categoryIn: [type.value] }
    : { equipmentTypeIn: [type.value] };
});

type PickerPage = {
  items: Item[];
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
            ...(query.value as ComponentQuery),
          },
        })
      : await fetchEquipment({
          ...params,
          q: {
            currentVersion: true,
            nameOrSlugCont: term,
            ...(query.value as EquipmentQuery),
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
    "compare-picker",
    props.kind,
    query.value,
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

const selectedIds = computed(
  () => new Set(selection.value.map((item) => item.id)),
);

const atMax = computed(() => taken.size + selection.value.length >= MAX_MODELS);

const cardDisabled = (item: Item) => {
  if (selectedIds.value.has(item.id)) return false;
  if (taken.has(item.slug) || atMax.value) return true;

  return !!lock.value && categoryOf(item)?.key !== lock.value.key;
};

const toggle = (item: Item) => {
  if (selectedIds.value.has(item.id)) {
    selection.value = selection.value.filter((entry) => entry.id !== item.id);
    return;
  }

  if (cardDisabled(item)) return;

  selection.value = [...selection.value, item];
};

const remove = (id: string) => {
  selection.value = selection.value.filter((entry) => entry.id !== id);
};

const imageOf = (item: Item) => {
  const image = compareItemImage(item);

  return image?.mediumUrl || image?.smallUrl || undefined;
};

const subtitleOf = (item: Item) => {
  const kindLabel =
    props.kind === "Component"
      ? (item as Component).category
        ? categoryLabel((item as Component).category as string)
        : undefined
      : ((item as Equipment).itemTypeLabel ??
        (item as Equipment).equipmentTypeLabel);

  return [item.manufacturer?.name, kindLabel].filter(Boolean).join(" · ");
};

const badgesOf = (item: Item) =>
  taken.has(item.slug)
    ? [
        {
          key: "comparing",
          label: t("modelPicker.badges.comparing"),
          primary: true,
        },
      ]
    : [];

const save = () => {
  replace([...taken, ...selection.value.map((item) => item.slug)]);
  // The write is debounced and would be dropped as the modal unmounts.
  flush();

  comlink.emit("close-modal", true);
};

const title = computed(() =>
  props.kind === "Component"
    ? t("labels.compare.selectComponents")
    : t("labels.compare.selectEquipment"),
);

const resultsLabel = computed(() =>
  props.kind === "Component"
    ? t("labels.compare.componentCount", { count: totalCount.value })
    : t("labels.compare.equipmentCount", { count: totalCount.value }),
);
</script>

<template>
  <Modal :title="title" flush>
    <!-- Enter belongs to the search; only the button saves. -->
    <form
      class="catalogue-picker"
      :class="{
        'catalogue-picker--folded': mobile,
        'catalogue-picker--tray': selection.length,
      }"
      @submit.prevent
    >
      <div class="catalogue-picker__header">
        <div class="catalogue-picker__toolbar">
          <FormInput
            v-model="search"
            name="compare-picker-search"
            class="catalogue-picker__search"
            :label="t('labels.logistics.itemPicker.search')"
            :placeholder="t('labels.logistics.itemPicker.search')"
            icon="fa-light fa-magnifying-glass"
            autofocus
            no-label
            clearable
          />

          <BaseSelect
            v-if="!lock"
            v-model="type"
            class="catalogue-picker__filter"
            name="compare-picker-type"
            :options="typeOptions || []"
            :label="
              kind === 'Component'
                ? t('labels.component.category')
                : t('labels.filters.equipment.equipmentType')
            "
            :searchable="true"
            :nullable="true"
          />
        </div>

        <div class="catalogue-picker__summary">
          <span class="catalogue-picker__count">{{ resultsLabel }}</span>
          <span v-if="lock" class="catalogue-picker__lock">
            {{ t("labels.compare.onlyCategory", { category: lock.label }) }}
          </span>
          <span v-if="atMax" class="catalogue-picker__hint">
            {{ t("labels.compare.enoughItems") }}
          </span>
        </div>
      </div>

      <Loader v-if="initialLoading" :loading="true" inline />

      <div
        v-else-if="records.length"
        class="catalogue-picker__grid"
        :class="{ 'catalogue-picker__grid--refreshing': refreshing }"
      >
        <PickerCard
          v-for="item in records"
          :key="item.id"
          :name="item.name"
          :subtitle="subtitleOf(item)"
          :image="imageOf(item)"
          image-fit="contain"
          :badges="badgesOf(item)"
          :selected="selectedIds.has(item.id)"
          :disabled="cardDisabled(item)"
          :data-test="`compare-picker-card-${item.slug}`"
          @toggle="toggle(item)"
        >
          <template #placeholder>
            <HardpointCategoryIcon
              v-if="kind === 'Component'"
              :category="(item as Component).category"
            />
            <EquipmentIcon v-else :equipment="item as Equipment" />
          </template>
        </PickerCard>
      </div>

      <Empty
        v-if="!isFetching && !records.length"
        :variant="EmptyVariantsEnum.DEFAULT"
        inline
        hide-actions
      />

      <div v-if="hasMore" class="catalogue-picker__more">
        <Btn
          :loading="isFetching"
          :variant="BtnVariantsEnum.BARE"
          @click="loadMore"
        >
          {{ t("actions.loadMore") }}
        </Btn>
      </div>

      <div v-if="selection.length" class="catalogue-picker__tray">
        <Chip
          v-for="item in selection"
          :key="item.id"
          :state="ChipStatesEnum.INCLUDED"
          @toggle="remove(item.id)"
        >
          {{ item.name }}
        </Chip>
      </div>
    </form>

    <template #footer-start>
      <span class="catalogue-picker__selected">
        {{ t("modelPicker.labels.selected", { count: selection.length }) }}
      </span>
    </template>
    <template #footer>
      <Btn
        v-if="selection.length"
        :variant="BtnVariantsEnum.GHOST"
        @click="selection = []"
      >
        {{ t("modelPicker.actions.clearSelection") }}
      </Btn>
      <Btn
        :disabled="!selection.length"
        data-test="compare-picker-submit"
        @click="save"
      >
        {{ t("actions.compare.item") }}
      </Btn>
    </template>
  </Modal>
</template>

<style scoped>
@reference "../../../../entrypoints/tailwind.css";

/* The ship picker's layout, for the same reasons: the header and the tray stay
   in view while the grid scrolls between them, so both run out to the flush
   body's edges and are opaque. */
.catalogue-picker {
  padding: 0 var(--modal-gutter, 24px) 24px;
}

.catalogue-picker--tray {
  padding-bottom: 0;
}

.catalogue-picker__header {
  @apply bg-gray-darker sticky top-0 z-[3];
  margin: 0 calc(-1 * var(--modal-gutter, 24px));
  padding: 20px var(--modal-gutter, 24px) 0;
}

.catalogue-picker__toolbar {
  @apply flex flex-wrap items-start gap-3;
}

.catalogue-picker__search {
  @apply min-w-[240px] flex-1;
}

.catalogue-picker--folded .catalogue-picker__search {
  @apply min-w-0;
}

.catalogue-picker__filter {
  @apply min-w-[200px] flex-1;
}

.catalogue-picker__summary {
  @apply flex flex-wrap items-center gap-3;
  padding: 2px 0 12px;
}

.catalogue-picker__count,
.catalogue-picker__lock {
  @apply text-muted text-[13px];
  font-variant-numeric: tabular-nums;
}

.catalogue-picker__hint {
  @apply text-gold text-[13px];
}

.catalogue-picker__grid {
  @apply grid gap-3;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
}

.catalogue-picker--folded .catalogue-picker__grid {
  grid-template-columns: repeat(
    auto-fill,
    minmax(min(150px, calc((100% - 12px) / 2)), 1fr)
  );
}

.catalogue-picker__grid--refreshing {
  @apply pointer-events-none opacity-50;
  transition: opacity 150ms ease-in-out;
}

.catalogue-picker__more {
  @apply flex justify-center;
  padding-top: 12px;
}

.catalogue-picker__tray {
  @apply bg-gray-darker sticky bottom-0 z-[3];
  @apply flex max-h-[84px] flex-wrap gap-2 overflow-y-auto;
  border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  margin: 12px calc(-1 * var(--modal-gutter, 24px)) 0;
  padding: 12px var(--modal-gutter, 24px);
}

.catalogue-picker__selected {
  @apply text-[15px];
  font-variant-numeric: tabular-nums;
}

@media (prefers-reduced-motion: reduce) {
  .catalogue-picker__grid--refreshing {
    transition-duration: 1ms;
  }
}
</style>
