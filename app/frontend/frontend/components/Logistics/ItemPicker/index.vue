<script lang="ts">
export default {
  name: "LogisticsItemPicker",
};
</script>

<script lang="ts" setup>
import { keepPreviousData, useQuery } from "@tanstack/vue-query";
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Row from "@/frontend/components/Logistics/ItemPicker/Row/index.vue";
import {
  INVENTORY_EQUIPMENT_TYPES,
  useInventoryOptions,
} from "@/frontend/composables/useInventoryOptions";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ItemPickerEntry,
  type ItemPickerSelection,
  type PickedItem,
} from "@/frontend/components/Logistics/types";
import {
  type FilterOption,
  type InventoryCategoryEnum,
  commodities as fetchCommodities,
  commodityTypesFilters,
  componentCategoriesFilters,
  components as fetchComponents,
  equipment as fetchEquipment,
  equipmentItemTypesFilters,
} from "@/services/fyApi";

type Props = {
  // The category the picker opens on; the form's, so a reopened picker lands
  // where the last pick came from.
  category?: string;
  // Narrows the categories on offer, for a form that cannot take all of them.
  categories?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  category: undefined,
  categories: undefined,
});

const emit = defineEmits<{
  select: [selection: ItemPickerSelection];
}>();

const PER_PAGE = "30";

const { t } = useI18n();

const { categoryOptions } = useInventoryOptions();

const availableCategories = computed(() =>
  props.categories
    ? categoryOptions.value.filter((option) =>
        props.categories?.includes(String(option.value)),
      )
    : categoryOptions.value,
);

const offered = (value?: string) =>
  availableCategories.value.some((option) => option.value === value);

const category = ref<string | undefined>(
  offered(props.category) ? props.category : undefined,
);
const itemType = ref<string | undefined>(undefined);
const search = ref("");
const searchTerm = ref("");
const page = ref(1);
const records = ref<ItemPickerEntry[]>([]);

const equipmentTypes = computed(() =>
  category.value ? INVENTORY_EQUIPMENT_TYPES[category.value] : undefined,
);

// Components, commodities and equipment are three catalogues behind three
// endpoints, and the category is what says which one is meant. Without one
// there is nothing to ask for, so nothing is.
const catalogue = computed<ItemPickerEntry["type"] | undefined>(() => {
  if (category.value === "component") return "Component";
  if (category.value === "commodity") return "Commodity";
  if (equipmentTypes.value) return "Equipment";

  return undefined;
});

const typeFilterLabel = computed(() => {
  if (catalogue.value === "Component") {
    return t("labels.logistics.componentCategory");
  }

  if (catalogue.value === "Commodity") {
    return t("labels.logistics.commodityType");
  }

  return t("labels.logistics.equipmentItemType");
});

const { data: typeOptions } = useQuery({
  queryKey: computed(() => [
    "inventory-item-picker-types",
    catalogue.value,
    equipmentTypes.value,
  ]),
  queryFn: (): Promise<FilterOption[]> => {
    if (catalogue.value === "Component") return componentCategoriesFilters();
    if (catalogue.value === "Commodity") return commodityTypesFilters();

    return equipmentItemTypesFilters({
      q: { equipmentTypeIn: equipmentTypes.value },
    });
  },
  enabled: computed(() => !!catalogue.value),
  refetchOnWindowFocus: false,
});

type PickerPage = {
  entries: ItemPickerEntry[];
  currentPage: number;
  totalPages: number;
  totalCount: number;
};

const fetchPage = async (): Promise<PickerPage> => {
  const params = { page: String(page.value), perPage: PER_PAGE };
  const typeIn = itemType.value ? [itemType.value] : undefined;
  const term = searchTerm.value || undefined;

  const respond = <T,>(
    response: {
      items: T[];
      meta?: {
        pagination?: {
          currentPage?: number;
          totalPages?: number;
          totalCount?: number;
        } | null;
      };
    },
    wrap: (record: T) => ItemPickerEntry,
  ): PickerPage => ({
    entries: response.items.map(wrap),
    currentPage: response.meta?.pagination?.currentPage ?? 1,
    totalPages: response.meta?.pagination?.totalPages ?? 1,
    totalCount: response.meta?.pagination?.totalCount ?? response.items.length,
  });

  if (catalogue.value === "Component") {
    return respond(
      await fetchComponents({
        ...params,
        q: {
          currentVersion: true,
          hiddenEq: false,
          categoryIn: typeIn,
          // Searches what players call a part too, so "mining bag" finds the
          // ore pods.
          searchNameCont: term,
        },
      }),
      (record) => ({ type: "Component", record }),
    );
  }

  if (catalogue.value === "Commodity") {
    return respond(
      await fetchCommodities({
        ...params,
        q: { commodityTypeIn: typeIn, nameCont: term },
      }),
      (record) => ({ type: "Commodity", record }),
    );
  }

  return respond(
    await fetchEquipment({
      ...params,
      q: {
        equipmentTypeIn: equipmentTypes.value,
        itemTypeIn: typeIn,
        nameOrSlugCont: term,
      },
    }),
    (record) => ({ type: "Equipment", record }),
  );
};

const { data, isFetching } = useQuery({
  queryKey: computed(() => [
    "inventory-item-picker",
    category.value,
    itemType.value,
    searchTerm.value,
    page.value,
  ]),
  queryFn: fetchPage,
  enabled: computed(() => !!catalogue.value),
  refetchOnWindowFocus: false,
  // Holds the last page while the next one loads, so the count and the
  // sentinel do not flicker off between pages.
  placeholderData: keepPreviousData,
});

// Which page arrived decides whether it extends the list or replaces it, and
// the response says so itself: a stale page 2 must not land on a list a filter
// change already reset.
watch(
  data,
  (response) => {
    if (!response || !catalogue.value) return;

    if (response.currentPage <= 1) {
      records.value = response.entries;
      return;
    }

    const known = new Set(records.value.map((entry) => entry.record.id));

    records.value = [
      ...records.value,
      ...response.entries.filter((entry) => !known.has(entry.record.id)),
    ];
  },
  { immediate: true },
);

const hasMore = computed(
  () => !!data.value && page.value < data.value.totalPages,
);

const initialLoading = computed(
  () => !!catalogue.value && isFetching.value && !records.value.length,
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

watch(category, () => {
  itemType.value = undefined;
  records.value = [];
  page.value = 1;
});

watch(itemType, () => {
  page.value = 1;
});

const loadMore = () => {
  if (!hasMore.value || isFetching.value) return;

  page.value += 1;
};

// Rooted at the modal's body, which is what scrolls: against the viewport the
// sentinel would only count once it was already on screen, and the margin
// would buy no prefetch.
const sentinel = ref<HTMLElement | null>(null);

let observer: IntersectionObserver | null = null;

const observe = () => {
  observer?.disconnect();
  observer = null;

  if (!sentinel.value) return;

  // eslint-disable-next-line compat/compat
  observer = new IntersectionObserver(
    (entries) => {
      if (entries[0]?.isIntersecting) loadMore();
    },
    {
      root: sentinel.value.closest(".modal-body"),
      rootMargin: "300px",
    },
  );

  observer.observe(sentinel.value);
};

watch(sentinel, observe);

// A page can be shorter than the gap the sentinel needs to leave the root, and
// an observer only reports changes. Re-observing asks it again.
watch(records, () => {
  if (!observer || !sentinel.value) return;

  observer.unobserve(sentinel.value);
  observer.observe(sentinel.value);
});

onUnmounted(() => {
  observer?.disconnect();
  observer = null;
  applySearch.cancel();
});

const customName = computed(() => searchTerm.value.trim());

const emitSelection = (name: string, item?: PickedItem) => {
  if (!category.value) return;

  emit("select", {
    item,
    name,
    category: category.value as InventoryCategoryEnum,
  });
};

const pick = (entry: ItemPickerEntry) => {
  emitSelection(entry.record.name, {
    type: entry.type,
    id: entry.record.id,
    name: entry.record.name,
    counted: entry.type === "Commodity" ? entry.record.counted : undefined,
  });
};

// Goods the catalogue does not carry are still goods: the search names them
// and the category files them.
const pickCustom = () => {
  if (customName.value.length < 2) return;

  emitSelection(customName.value);
};
</script>

<template>
  <!-- Enter belongs to the search; a pick is a click on a row. -->
  <form class="item-picker" @submit.prevent>
    <div class="item-picker__header">
      <div class="item-picker__toolbar">
        <BaseSelect
          v-model="category"
          class="item-picker__filter"
          name="item-picker-category"
          :options="availableCategories"
          :label="t('labels.logistics.category')"
          :searchable="false"
        />

        <BaseSelect
          :key="category || 'none'"
          v-model="itemType"
          class="item-picker__filter"
          name="item-picker-type"
          :options="typeOptions || []"
          :label="typeFilterLabel"
          :disabled="!catalogue"
          :searchable="true"
          :nullable="true"
        />
      </div>

      <FormInput
        v-model="search"
        name="item-picker-search"
        :label="t('labels.logistics.itemPicker.search')"
        :placeholder="t('labels.logistics.itemPicker.search')"
        :disabled="!catalogue"
        icon="fa-light fa-magnifying-glass"
        no-label
        clearable
        standalone
      />

      <p v-if="catalogue && data" class="item-picker__count">
        {{
          t("labels.logistics.itemPicker.results", {
            count: data.totalCount,
          })
        }}
      </p>

      <Btn
        v-if="catalogue && customName.length >= 2"
        class="item-picker__custom"
        :variant="BtnVariantsEnum.GHOST"
        data-test="item-picker-custom"
        block
        @click="pickCustom"
      >
        <i class="fa-light fa-plus" />
        {{ t("labels.logistics.itemPicker.custom", { name: customName }) }}
      </Btn>
    </div>

    <p v-if="!catalogue" class="item-picker__prompt">
      <i class="fa-duotone fa-boxes-stacked" />
      {{ t("labels.logistics.itemPicker.chooseCategory") }}
    </p>

    <Loader v-else-if="initialLoading" :loading="true" inline />

    <div
      v-else-if="records.length"
      class="item-picker__list"
      :class="{ 'item-picker__list--refreshing': refreshing }"
    >
      <Row
        v-for="entry in records"
        :key="entry.record.id"
        :entry="entry"
        @pick="pick(entry)"
      />
    </div>

    <p v-else class="item-picker__prompt">
      {{ t("labels.logistics.itemPicker.noResults") }}
    </p>

    <div v-if="hasMore" ref="sentinel" class="item-picker__more">
      <Btn
        :loading="isFetching"
        :variant="BtnVariantsEnum.BARE"
        @click="loadMore"
      >
        {{ t("actions.loadMore") }}
      </Btn>
    </div>
  </form>
</template>

<style lang="scss" scoped>
// The body is flush, so the sticky header can run out to its edges: inside a
// padded scroller it stopped short of them and the rows showed through.
.item-picker {
  padding: 0 var(--modal-gutter, 24px) 24px;
}

// Opaque, because the rows scroll under it: --color-surface is 90% alpha.
.item-picker__header {
  position: sticky;
  top: 0;
  z-index: 3;
  margin: 0 calc(-1 * var(--modal-gutter, 24px));
  padding: 20px var(--modal-gutter, 24px) 0;
  background-color: var(--color-gray-darker, #272b30);
}

.item-picker__toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 0 12px;
}

.item-picker__filter {
  flex: 1 1 200px;
  min-width: 0;
}

.item-picker__count {
  margin: 0;
  padding: 0 0 12px;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
  color: var(--color-text-dim, #959595);
}

.item-picker__custom {
  margin-bottom: 12px;
}

.item-picker__list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

// Re-filtering leaves the old results readable but marks them as stale.
.item-picker__list--refreshing {
  pointer-events: none;
  opacity: 0.5;
  transition: opacity 150ms ease-in-out;
}

.item-picker__prompt {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  margin: 0;
  padding: 40px 0 24px;
  text-align: center;
  color: var(--color-text-dim, #959595);

  i {
    font-size: 32px;
    color: var(--color-muted, #7a8288);
  }
}

.item-picker__more {
  display: flex;
  justify-content: center;
  padding-top: 12px;
}

@media (prefers-reduced-motion: reduce) {
  .item-picker__list--refreshing {
    transition-duration: 1ms;
  }
}
</style>
