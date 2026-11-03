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
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Row from "@/frontend/components/Logistics/ItemPicker/Row/index.vue";
import type { ItemPickerEntry } from "@/frontend/components/Logistics/types";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import {
  componentCompareCategory,
  equipmentCompareCategory,
  type CompareCategory,
} from "@/frontend/components/Compare/category";
import { useCompareSet } from "@/frontend/composables/useCompareSet";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import {
  componentCategoriesFilters,
  components as fetchComponents,
  equipment as fetchEquipment,
  equipmentTypesFilters,
  type ComponentQuery,
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

const PER_PAGE = "30";

const { t, tExists } = useI18n();

const comlink = useComlink();

const { slugs: stored, replace, flush } = useCompareSet(props.queryKey);

// Picks still on their way to the URL, which only takes a write after a
// debounce. Counted as held, so a quick second pick builds on the first rather
// than on the set the URL still shows.
const pending = ref<string[]>([]);

const slugs = computed(() => [...new Set([...stored.value, ...pending.value])]);

watch(stored, (current) => {
  pending.value = pending.value.filter((slug) => !current.includes(slug));
});

onBeforeUnmount(flush);

const lock = ref(props.lock);

const type = ref<string | undefined>();
const search = ref("");
const searchTerm = ref("");
const page = ref(1);
const records = ref<ItemPickerEntry[]>([]);

const { data: typeOptions } = useQuery({
  queryKey: ["compare-picker-types", props.kind],
  queryFn: () =>
    props.kind === "Component"
      ? componentCategoriesFilters()
      : equipmentTypesFilters(),
  enabled: computed(() => !lock.value),
  refetchOnWindowFocus: false,
});

const query = computed(() => {
  if (lock.value) return lock.value.query;
  if (!type.value) return {};

  return props.kind === "Component"
    ? { categoryIn: [type.value] }
    : { equipmentTypeIn: [type.value] };
});

type PickerPage = {
  entries: ItemPickerEntry[];
  currentPage: number;
  totalPages: number;
};

const fetchPage = async (): Promise<PickerPage> => {
  const params = { page: String(page.value), perPage: PER_PAGE };
  const term = searchTerm.value || undefined;

  if (props.kind === "Component") {
    const response = await fetchComponents({
      ...params,
      q: {
        currentVersion: true,
        hiddenEq: false,
        searchNameCont: term,
        ...(query.value as ComponentQuery),
      },
    });

    return {
      entries: response.items.map((record) => ({ type: "Component", record })),
      currentPage: response.meta?.pagination?.currentPage ?? 1,
      totalPages: response.meta?.pagination?.totalPages ?? 1,
    };
  }

  const response = await fetchEquipment({
    ...params,
    q: {
      currentVersion: true,
      nameOrSlugCont: term,
      ...(query.value as EquipmentQuery),
    },
  });

  return {
    entries: response.items.map((record) => ({ type: "Equipment", record })),
    currentPage: response.meta?.pagination?.currentPage ?? 1,
    totalPages: response.meta?.pagination?.totalPages ?? 1,
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

// The page that arrived says whether it extends the list or replaces it, so a
// stale page 2 cannot land on a list a new search already reset.
watch(
  [data, isPlaceholderData],
  ([response, placeholder]) => {
    if (!response || placeholder) return;

    totalPages.value = response.totalPages;

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

// What is already compared stays off the list rather than offered twice.
const offered = computed(() =>
  records.value.filter((entry) => !slugs.value.includes(entry.record.slug)),
);

const hasMore = computed(
  () => !isPlaceholderData.value && page.value < totalPages.value,
);

const initialLoading = computed(
  () => isFetching.value && !records.value.length,
);

const applySearch = debounce((value: string) => {
  searchTerm.value = value;
  page.value = 1;
}, 300);

watch(search, (value) => {
  applySearch(value);
});

watch([type, lock], () => {
  page.value = 1;
});

onUnmounted(() => {
  applySearch.cancel();
});

const loadMore = () => {
  if (!hasMore.value || isFetching.value) return;

  page.value += 1;
};

const categoryLabel = (category: string) => {
  const path = `labels.hardpoint.categories.${category}`;

  return tExists(path) ? t(path) : category;
};

const remaining = computed(() => MAX_MODELS - slugs.value.length);

const close = () => {
  comlink.emit("close-modal", true);
};

// Added straight away rather than collected for a submit: the table behind the
// modal fills in as the reader picks, and the modal stays open for the next.
const pick = (entry: ItemPickerEntry) => {
  const next = [...slugs.value, entry.record.slug];

  if (!lock.value) {
    lock.value =
      entry.type === "Component"
        ? componentCompareCategory(entry.record, categoryLabel)
        : entry.type === "Equipment"
          ? equipmentCompareCategory(entry.record)
          : undefined;
  }

  pending.value = [...pending.value, entry.record.slug];
  replace(next);

  if (next.length >= MAX_MODELS) close();
};

const title = computed(() =>
  props.kind === "Component"
    ? t("labels.compare.selectComponents")
    : t("labels.compare.selectEquipment"),
);
</script>

<template>
  <Modal :title="title" flush>
    <div class="compare-picker">
      <div class="compare-picker__header">
        <p v-if="lock" class="compare-picker__lock">
          {{ t("labels.compare.onlyCategory", { category: lock.label }) }}
        </p>
        <BaseSelect
          v-else
          v-model="type"
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

        <FormInput
          v-model="search"
          name="compare-picker-search"
          :label="t('labels.logistics.itemPicker.search')"
          :placeholder="t('labels.logistics.itemPicker.search')"
          icon="fa-light fa-magnifying-glass"
          no-label
          clearable
          standalone
        />

        <p class="compare-picker__count">
          {{ t("labels.compare.remaining", { count: remaining }) }}
        </p>
      </div>

      <Loader v-if="initialLoading" :loading="true" inline />

      <div v-else-if="offered.length" class="compare-picker__list">
        <Row
          v-for="entry in offered"
          :key="entry.record.id"
          :entry="entry"
          @pick="pick(entry)"
        />
      </div>

      <p v-else class="compare-picker__empty">
        {{ t("labels.logistics.itemPicker.noResults") }}
      </p>

      <div v-if="hasMore" class="compare-picker__more">
        <Btn
          :loading="isFetching"
          :variant="BtnVariantsEnum.BARE"
          @click="loadMore"
        >
          {{ t("actions.loadMore") }}
        </Btn>
      </div>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
.compare-picker {
  padding: 0 var(--modal-gutter, 24px) 24px;
}

// Opaque, because the rows scroll under it: --color-surface is 90% alpha.
.compare-picker__header {
  position: sticky;
  top: 0;
  z-index: 3;
  margin: 0 calc(-1 * var(--modal-gutter, 24px));
  padding: 20px var(--modal-gutter, 24px) 0;
  background-color: var(--color-gray-darker, #272b30);
}

.compare-picker__lock,
.compare-picker__count {
  margin: 0;
  padding: 0 0 12px;
  font-size: 0.8125rem;
  color: var(--color-text-dim, #959595);
}

.compare-picker__count {
  font-variant-numeric: tabular-nums;
}

.compare-picker__list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.compare-picker__empty {
  margin: 0;
  padding: 40px 0 24px;
  text-align: center;
  color: var(--color-text-dim, #959595);
}

.compare-picker__more {
  display: flex;
  justify-content: center;
  padding-top: 12px;
}
</style>
