<script lang="ts">
export default {
  name: "NewVehiclesModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
import ClassificationSelect from "@/frontend/components/base/ModelClassificationSelect/index.vue";
import ModelCard from "@/frontend/components/Vehicles/NewVehiclesModal/ModelCard/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import {
  type ModelOption,
  type ModelQuery,
  useModelOptions,
} from "@/services/fyApi";
import { keepPreviousData } from "@tanstack/vue-query";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import debounce from "lodash.debounce";

type Props = {
  wanted?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wanted: false,
});

type Selected = {
  option: ModelOption;
  quantity: number;
};

const PER_PAGE = "24";

const { t } = useI18n();

const comlink = useComlink();

const { useCreateBulkMutation } = useVehicleMutations();

const mutation = useCreateBulkMutation();

const submitting = ref(false);

const search = ref<string>("");
const searchTerm = ref<string>("");
const manufacturerIn = ref<string[]>([]);
const classificationIn = ref<string[]>([]);

const page = ref(1);
const records = ref<ModelOption[]>([]);
const selection = ref<Selected[]>([]);

const queryParams = computed(() => {
  const q: ModelQuery = {};

  // searchCont, not nameCont: it is aliased to name-or-slug-or-manufacturer, so
  // typing "anvil" finds the manufacturer's ships rather than nothing.
  if (searchTerm.value) {
    q.searchCont = searchTerm.value;
  }

  if (manufacturerIn.value.length) {
    q.manufacturerIn = manufacturerIn.value;
  }

  if (classificationIn.value.length) {
    q.classificationIn = classificationIn.value;
  }

  return {
    page: String(page.value),
    perPage: PER_PAGE,
    q,
  };
});

const { data, isFetching, isLoading } = useModelOptions(queryParams, {
  query: {
    refetchOnWindowFocus: false,
    // Without it `data` is undefined for the length of every fetch, and the
    // result count, `hasMore` and the sentinel it mounts all flicker off and
    // back on between pages. The accumulator below is keyed on the response's
    // own page, so holding the previous one costs nothing.
    placeholderData: keepPreviousData,
  },
});

/**
 * Which page arrived decides whether this response extends the list or replaces
 * it, and the response says so itself. Reading `page` here instead would append
 * a stale page-2 payload onto a list a filter change had already reset to 1.
 */
watch(
  data,
  (response) => {
    if (!response) return;

    if ((response.meta.pagination?.currentPage ?? 1) <= 1) {
      records.value = response.items;
      return;
    }

    const existing = new Set(records.value.map((item) => item.id));
    records.value = [
      ...records.value,
      ...response.items.filter((item) => !existing.has(item.id)),
    ];
  },
  { immediate: true },
);

const totalPages = computed(() => data.value?.meta.pagination?.totalPages ?? 1);

const totalCount = computed(
  () => data.value?.meta.pagination?.totalCount ?? records.value.length,
);

const hasMore = computed(() => page.value < totalPages.value);

const loading = computed(() => isLoading.value || isFetching.value);

// Only the first page of a new query blanks the grid. Paging in more never does,
// and neither does re-filtering: the list you were reading stays put, dimmed,
// until its replacement is ready.
const initialLoading = computed(() => loading.value && !records.value.length);

const refreshing = computed(
  () => loading.value && page.value === 1 && !!records.value.length,
);

const applySearch = debounce((value: string) => {
  searchTerm.value = value;
  page.value = 1;
}, 300);

watch(search, (value) => {
  applySearch(value);
});

watch([manufacturerIn, classificationIn], () => {
  page.value = 1;
});

const filtersActive = computed(
  () =>
    !!searchTerm.value ||
    !!manufacturerIn.value.length ||
    !!classificationIn.value.length,
);

const resetFilters = () => {
  search.value = "";
  searchTerm.value = "";
  manufacturerIn.value = [];
  classificationIn.value = [];
  page.value = 1;
};

const loadMore = () => {
  if (!hasMore.value || loading.value) return;

  page.value += 1;
};

/**
 * The scroll container is the modal's body, not the window, so the observer has
 * to be rooted there for `rootMargin` to buy any prefetch at all - against the
 * viewport the ancestor's clip rect is not expanded and the sentinel only counts
 * as visible once it is already on screen. Falls back to the viewport if the
 * modal chrome ever stops providing that element.
 */
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

// A page of cards can be shorter than the gap the sentinel needs to leave the
// root, and an observer only reports changes. Re-observing asks it again.
watch(records, () => {
  if (!observer || !sentinel.value) return;

  observer.unobserve(sentinel.value);
  observer.observe(sentinel.value);
});

onUnmounted(() => {
  observer?.disconnect();
  observer = null;
});

const selectedIds = computed(
  () => new Set(selection.value.map((item) => item.option.id)),
);

const selectedTotal = computed(() =>
  selection.value.reduce((sum, item) => sum + item.quantity, 0),
);

const quantityFor = (id: string) =>
  selection.value.find((item) => item.option.id === id)?.quantity ?? 1;

const toggle = (option: ModelOption) => {
  if (selectedIds.value.has(option.id)) {
    remove(option.id);
    return;
  }

  selection.value = [...selection.value, { option, quantity: 1 }];
};

const remove = (id: string) => {
  selection.value = selection.value.filter((item) => item.option.id !== id);
};

const changeQuantity = (id: string, by: number) => {
  selection.value = selection.value.map((item) =>
    item.option.id === id
      ? { ...item, quantity: Math.max(1, item.quantity + by) }
      : item,
  );
};

const clearSelection = () => {
  selection.value = [];
};

const title = computed(() =>
  props.wanted ? t("newVehicles.wishlistTitle") : t("newVehicles.title"),
);

const submitLabel = computed(() =>
  props.wanted ? t("actions.addToWishlist") : t("actions.addToHangar"),
);

const save = async () => {
  if (!selection.value.length) return;

  submitting.value = true;

  // One vehicle per copy: the endpoint takes a flat list, so a quantity of three
  // is the same model three times over.
  const vehicles = selection.value.flatMap(({ option, quantity }) =>
    Array.from({ length: quantity }, () => ({
      wanted: props.wanted,
      modelId: option.id,
    })),
  );

  await mutation
    .mutateAsync({ data: { vehicles } })
    .then(() => {
      comlink.emit("hangar-change");
    })
    .finally(() => {
      submitting.value = false;
      comlink.emit("close-modal");
    });
};
</script>

<template>
  <Modal :title="title">
    <form id="new-vehicles" class="new-vehicles" @submit.prevent="save">
      <div class="new-vehicles__header">
        <div class="new-vehicles__toolbar">
          <FormInput
            v-model="search"
            name="new-vehicles-search"
            class="new-vehicles__search"
            :label="t('newVehicles.labels.search')"
            :placeholder="t('newVehicles.labels.search')"
            icon="fa-light fa-magnifying-glass"
            autofocus
            no-label
            clearable
          />

          <ManufacturerSelect
            v-model="manufacturerIn"
            class="new-vehicles__filter"
            name="new-vehicles-manufacturer"
          />

          <ClassificationSelect
            v-model="classificationIn"
            class="new-vehicles__filter"
            name="new-vehicles-classification"
          />
        </div>

        <div class="new-vehicles__summary">
          <span class="new-vehicles__count">
            {{ t("newVehicles.labels.results", { count: totalCount }) }}
          </span>
          <Btn
            v-if="filtersActive"
            :variant="BtnVariantsEnum.BARE"
            :size="BtnSizesEnum.XS"
            @click="resetFilters"
          >
            {{ t("newVehicles.actions.resetFilters") }}
          </Btn>
        </div>
      </div>

      <Loader v-if="initialLoading" :loading="true" inline />

      <div
        v-else-if="records.length"
        class="new-vehicles__grid"
        :class="{ 'new-vehicles__grid--refreshing': refreshing }"
      >
        <ModelCard
          v-for="option in records"
          :key="option.id"
          :option="option"
          :wanted="wanted"
          :selected="selectedIds.has(option.id)"
          :quantity="quantityFor(option.id)"
          @toggle="toggle(option)"
          @increase="changeQuantity(option.id, 1)"
          @decrease="changeQuantity(option.id, -1)"
        />
      </div>

      <Empty
        v-if="!loading && !records.length"
        :variant="EmptyVariantsEnum.DEFAULT"
        :name="t('models.name')"
        inline
        hide-actions
      />

      <div v-if="hasMore" ref="sentinel" class="new-vehicles__more">
        <Btn
          :loading="loading"
          :variant="BtnVariantsEnum.BARE"
          @click="loadMore"
        >
          {{ t("actions.loadMore") }}
        </Btn>
      </div>

      <!--
        Stuck to the bottom of the scroll area rather than living in the modal's
        footer. The footer is outside `.modal-body`, whose max-height is sized for
        a single row of actions, so a tray of chips there pushed the submit button
        off the bottom of the viewport. Here it costs the grid height it uses and
        stays in view while you scroll, which is the whole point of it.
      -->
      <div v-if="selection.length" class="new-vehicles__tray">
        <Chip
          v-for="item in selection"
          :key="item.option.id"
          :state="ChipStatesEnum.INCLUDED"
          :count="item.quantity > 1 ? item.quantity : undefined"
          @toggle="remove(item.option.id)"
        >
          {{ item.option.name }}
        </Chip>
      </div>
    </form>

    <template #footer>
      <div class="new-vehicles__actions">
        <span class="new-vehicles__selected">
          {{ t("newVehicles.labels.selected", { count: selectedTotal }) }}
        </span>
        <Btn
          v-if="selection.length"
          :variant="BtnVariantsEnum.BARE"
          @click="clearSelection"
        >
          {{ t("newVehicles.actions.clearSelection") }}
        </Btn>
        <Btn
          :loading="submitting"
          :disabled="!selection.length"
          :size="BtnSizesEnum.LG"
          @click="save"
        >
          {{ submitLabel }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style scoped>
@reference "../../../../entrypoints/tailwind.css";

/* ---------- header ----------
   Search, filters and the result count all stay reachable while the grid scrolls
   under them, so the fill has to be opaque: --color-surface is 90% alpha and the
   cards would show through it. --color-gray-darker is that colour at full
   strength. */
.new-vehicles__header {
  @apply bg-gray-darker sticky top-0 z-[3];
}

.new-vehicles__toolbar {
  @apply flex flex-wrap items-start gap-3;
}

.new-vehicles__search {
  @apply min-w-[240px] flex-1;
}

.new-vehicles__filter {
  @apply min-w-[200px] flex-1;
}

/*
 * The filter sidebar opens these over a flat panel; here they open over a grid of
 * ship photos, and the 95%-alpha list fill plus the fully transparent search row
 * both let the images through. Opaque in this modal only - the component is
 * shared, and nowhere else has this behind it.
 */
.new-vehicles__filter :deep(.base-select-items-wrapper) {
  background-color: var(--color-gray-darker, #272b30);
}

.new-vehicles__summary {
  @apply flex items-center justify-between gap-3;
  padding: 2px 0 12px;
}

.new-vehicles__count {
  @apply text-muted text-[13px];
  font-variant-numeric: tabular-nums;
}

/* ---------- grid ----------
   auto-fill from 220px: four across the wide modal, and it steps down to one on
   a phone without a breakpoint per column count. */
.new-vehicles__grid {
  @apply grid gap-3;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
}

/* Re-filtering leaves the old results readable rather than blanking the grid,
   but marks them as no longer current. */
.new-vehicles__grid--refreshing {
  @apply pointer-events-none opacity-50;
  transition: opacity 150ms ease-in-out;
}

.new-vehicles__more {
  @apply flex justify-center;
  padding-top: 12px;
}

/* ---------- selection tray ----------
   Capped and scrollable so thirty chips cannot eat the whole grid, and opaque for
   the same reason the header is: the cards scroll behind it. */
.new-vehicles__tray {
  @apply bg-gray-darker sticky bottom-0 z-[3];
  @apply flex max-h-[84px] flex-wrap gap-2 overflow-y-auto;
  border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  padding: 12px 0 2px;
}

/* ---------- footer ---------- */
.new-vehicles__actions {
  @apply flex w-full flex-wrap items-center justify-end gap-3;
}

.new-vehicles__selected {
  @apply text-text mr-auto text-[15px] font-semibold;
  font-variant-numeric: tabular-nums;
}

@media (prefers-reduced-motion: reduce) {
  .new-vehicles__grid--refreshing {
    transition-duration: 1ms;
  }
}
</style>
