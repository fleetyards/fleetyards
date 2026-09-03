<script lang="ts">
export default {
  name: "ModelPickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
import ClassificationSelect from "@/frontend/components/base/ModelClassificationSelect/index.vue";
import ModelCard from "@/frontend/components/Models/PickerModal/ModelCard/index.vue";
import {
  type ModelPickerBadge,
  type ModelPickerSelection,
} from "@/frontend/components/Models/PickerModal/types";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import {
  ContainerSizeEnum,
  type ContainerFitQuery,
  type ModelOption,
  type ModelQuery,
  useModelOptions,
} from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { keepPreviousData } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import debounce from "lodash.debounce";

type Props = {
  title: string;
  submitLabel: string;
  submitting?: boolean;
  // The stepper only earns its place where a list can hold the same ship twice.
  quantities?: boolean;
  max?: number;
  maxHint?: string;
  highlight?: `${ModelPickerBadge}`;
  // Ships the caller's list already holds: shown, named by `takenNote`, unpickable.
  takenSlugs?: string[];
  takenNote?: string;
  // What the caller's list can display at all - a cargo grid has nothing to draw
  // for a ship without one. Narrows every query the picker makes, and the filters
  // below only ever narrow it further.
  query?: ModelQuery;
  // Offers a load to carry as a filter: only ships every counted container fits
  // into are shown.
  containerFilter?: boolean;
  // The load the filter starts on. Editing it here only narrows or widens what
  // the picker offers - the list you opened it from keeps the load it had.
  containerFit?: ContainerFitQuery;
  // Offers the hangar as a filter. Signed-out visitors have no hangar to filter
  // by, so they never see it.
  hangarFilter?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  submitting: false,
  quantities: false,
  max: undefined,
  maxHint: undefined,
  highlight: undefined,
  takenSlugs: () => [],
  takenNote: undefined,
  query: undefined,
  containerFilter: false,
  containerFit: undefined,
  hangarFilter: false,
});

const emit = defineEmits<{
  submit: [selection: ModelPickerSelection[]];
}>();

const PER_PAGE = "24";

const { t } = useI18n();

const sessionStore = useSessionStore();

const hangarOffered = computed(
  () => props.hangarFilter && sessionStore.isAuthenticated,
);

const search = ref<string>("");
const searchTerm = ref<string>("");
const manufacturerIn = ref<string[]>([]);
const classificationIn = ref<string[]>([]);
const hangarOnly = ref(false);

// The sizes the API knows, as the literal keys ContainerFitQuery declares - so
// the counts below index it without a cast, and a size added on the Ruby side
// reaches this filter without an edit.
const CONTAINER_SIZES = Object.values(ContainerSizeEnum);

// Left sparse rather than zero-filled: an empty counter reads as "none asked
// for", where a row of zeroes hides which sizes actually carry a load.
const containerCounts = ref<ContainerFitQuery>({ ...props.containerFit });

const containerCount = (size: `${ContainerSizeEnum}`) =>
  Number(containerCounts.value[size]) || 0;

const containerFit = computed<ContainerFitQuery | undefined>(() => {
  const fit: ContainerFitQuery = {};

  for (const size of CONTAINER_SIZES) {
    const quantity = containerCount(size);

    if (quantity > 0) {
      fit[size] = quantity;
    }
  }

  // Undefined rather than an empty map: the endpoint reads any present
  // containerFit as a load to check against, and an empty one fits nothing.
  return Object.keys(fit).length ? fit : undefined;
});

const page = ref(1);
const records = ref<ModelOption[]>([]);
const selection = ref<ModelPickerSelection[]>([]);

const queryParams = computed(() => {
  const q: ModelQuery = { ...props.query };

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

  if (hangarOnly.value) {
    q.inHangar = true;
  }

  return {
    page: String(page.value),
    perPage: PER_PAGE,
    q,
    containerFit: containerFit.value,
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

watch([manufacturerIn, classificationIn, hangarOnly, containerFit], () => {
  page.value = 1;
});

const filtersActive = computed(
  () =>
    !!searchTerm.value ||
    !!manufacturerIn.value.length ||
    !!classificationIn.value.length ||
    hangarOnly.value ||
    !!containerFit.value,
);

const resetFilters = () => {
  search.value = "";
  searchTerm.value = "";
  manufacturerIn.value = [];
  classificationIn.value = [];
  hangarOnly.value = false;
  containerCounts.value = {};
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

const takenSet = computed(() => new Set(props.takenSlugs));

const selectedIds = computed(
  () => new Set(selection.value.map((item) => item.option.id)),
);

const selectedTotal = computed(() =>
  selection.value.reduce((sum, item) => sum + item.quantity, 0),
);

// Copies count against the cap wherever quantities are offered: eight of one ship
// fills a hangar picker's budget the same way eight different ones do.
const atMax = computed(
  () => props.max !== undefined && selectedTotal.value >= props.max,
);

const cardDisabled = (option: ModelOption) =>
  takenSet.value.has(option.slug) ||
  (atMax.value && !selectedIds.value.has(option.id));

const quantityFor = (id: string) =>
  selection.value.find((item) => item.option.id === id)?.quantity ?? 1;

const toggle = (option: ModelOption) => {
  if (selectedIds.value.has(option.id)) {
    remove(option.id);
    return;
  }

  if (cardDisabled(option)) return;

  selection.value = [...selection.value, { option, quantity: 1 }];
};

const remove = (id: string) => {
  selection.value = selection.value.filter((item) => item.option.id !== id);
};

const changeQuantity = (id: string, by: number) => {
  if (by > 0 && atMax.value) return;

  selection.value = selection.value.map((item) =>
    item.option.id === id
      ? { ...item, quantity: Math.max(1, item.quantity + by) }
      : item,
  );
};

const clearSelection = () => {
  selection.value = [];
};

const save = () => {
  if (!selection.value.length) return;

  emit("submit", selection.value);
};
</script>

<template>
  <Modal :title="title">
    <form id="model-picker" class="model-picker" @submit.prevent="save">
      <div class="model-picker__header">
        <div class="model-picker__toolbar">
          <FormInput
            v-model="search"
            name="model-picker-search"
            class="model-picker__search"
            :label="t('modelPicker.labels.search')"
            :placeholder="t('modelPicker.labels.search')"
            icon="fa-light fa-magnifying-glass"
            autofocus
            no-label
            clearable
          />

          <ManufacturerSelect
            v-model="manufacturerIn"
            class="model-picker__filter"
            name="model-picker-manufacturer"
          />

          <ClassificationSelect
            v-model="classificationIn"
            class="model-picker__filter"
            name="model-picker-classification"
          />

          <Btn
            v-if="hangarOffered"
            class="model-picker__hangar"
            :active="hangarOnly"
            data-test="model-picker-hangar-only"
            @click="hangarOnly = !hangarOnly"
          >
            {{ t("modelPicker.labels.hangarOnly") }}
          </Btn>
        </div>

        <div v-if="containerFilter" class="model-picker__containers">
          <span class="model-picker__containers-label">
            {{ t("modelPicker.labels.containerFit") }}
          </span>
          <FormInput
            v-for="size in CONTAINER_SIZES"
            :key="size"
            v-model.number="containerCounts[size]"
            class="model-picker__container"
            :class="{
              'model-picker__container--set': containerCount(size) > 0,
            }"
            :name="`model-picker-container-${size}`"
            :label="`${size} SCU`"
            :type="InputTypesEnum.NUMBER"
            :min="0"
            :step="1"
            :alignment="InputAlignmentsEnum.RIGHT"
          />
        </div>

        <div class="model-picker__summary">
          <span class="model-picker__count">
            {{ t("modelPicker.labels.results", { count: totalCount }) }}
          </span>
          <span v-if="atMax && maxHint" class="model-picker__hint">
            {{ maxHint }}
          </span>
          <Btn
            v-if="filtersActive"
            class="model-picker__reset"
            :variant="BtnVariantsEnum.BARE"
            :size="BtnSizesEnum.XS"
            @click="resetFilters"
          >
            {{ t("modelPicker.actions.resetFilters") }}
          </Btn>
        </div>
      </div>

      <Loader v-if="initialLoading" :loading="true" inline />

      <div
        v-else-if="records.length"
        class="model-picker__grid"
        :class="{ 'model-picker__grid--refreshing': refreshing }"
      >
        <ModelCard
          v-for="option in records"
          :key="option.id"
          :option="option"
          :highlight="highlight"
          :quantities="quantities"
          :selected="selectedIds.has(option.id)"
          :quantity="quantityFor(option.id)"
          :disabled="cardDisabled(option)"
          :note="takenSet.has(option.slug) ? takenNote : undefined"
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

      <div v-if="hasMore" ref="sentinel" class="model-picker__more">
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
      <div v-if="selection.length" class="model-picker__tray">
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
      <div class="model-picker__actions">
        <span class="model-picker__selected">
          {{ t("modelPicker.labels.selected", { count: selectedTotal }) }}
        </span>
        <Btn
          v-if="selection.length"
          :variant="BtnVariantsEnum.BARE"
          @click="clearSelection"
        >
          {{ t("modelPicker.actions.clearSelection") }}
        </Btn>
        <Btn
          :loading="submitting"
          :disabled="!selection.length"
          :size="BtnSizesEnum.LG"
          data-test="model-picker-submit"
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
.model-picker__header {
  @apply bg-gray-darker sticky top-0 z-[3];
}

.model-picker__toolbar {
  @apply flex flex-wrap items-start gap-3;
}

.model-picker__search {
  @apply min-w-[240px] flex-1;
}

.model-picker__filter {
  @apply min-w-[200px] flex-1;
}

/*
 * The filter sidebar opens these over a flat panel; here they open over a grid of
 * ship photos, and the 95%-alpha list fill plus the fully transparent search row
 * both let the images through. Opaque in this modal only - the component is
 * shared, and nowhere else has this behind it.
 */
.model-picker__filter :deep(.base-select-items-wrapper) {
  background-color: var(--color-gray-darker, #272b30);
}

/* Matched to the fields it stands next to rather than sized by its own text, so
   the toolbar reads as one row. */
.model-picker__hangar {
  @apply self-stretch;
}

/* ---------- container filter ----------
   A row of narrow counters, one per size, that wraps rather than scrolls: the
   modal is wide but a phone fits three of them across. */
.model-picker__containers {
  @apply flex flex-wrap items-end gap-2;
  padding-top: 12px;
}

.model-picker__containers-label {
  @apply text-muted text-[13px];
  /* Level with the fields' labels, not with the inputs the flex row bottom-aligns. */
  @apply self-center;
}

.model-picker__container {
  @apply w-[4.5rem] shrink-0;
}

/* Which sizes are actually being asked for, readable without comparing seven
   numbers: an empty counter is silent, a filled one is marked. */
.model-picker__container--set :deep(input) {
  @apply text-gold font-semibold;
  border-color: var(--color-gold);
}

.model-picker__summary {
  @apply flex items-center gap-3;
  padding: 2px 0 12px;
}

.model-picker__count {
  @apply text-muted text-[13px];
  font-variant-numeric: tabular-nums;
}

/* Why the rest of the grid went out of reach, next to the count that no longer
   describes what you can pick from. */
.model-picker__hint {
  @apply text-gold text-[13px];
}

.model-picker__reset {
  @apply ml-auto;
}

/* ---------- grid ----------
   auto-fill from 220px: four across the wide modal, and it steps down to one on
   a phone without a breakpoint per column count. */
.model-picker__grid {
  @apply grid gap-3;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
}

/* Re-filtering leaves the old results readable rather than blanking the grid,
   but marks them as no longer current. */
.model-picker__grid--refreshing {
  @apply pointer-events-none opacity-50;
  transition: opacity 150ms ease-in-out;
}

.model-picker__more {
  @apply flex justify-center;
  padding-top: 12px;
}

/* ---------- selection tray ----------
   Capped and scrollable so thirty chips cannot eat the whole grid, and opaque for
   the same reason the header is: the cards scroll behind it. */
.model-picker__tray {
  @apply bg-gray-darker sticky bottom-0 z-[3];
  @apply flex max-h-[84px] flex-wrap gap-2 overflow-y-auto;
  border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  padding: 12px 0 2px;
}

/* ---------- footer ---------- */
.model-picker__actions {
  @apply flex w-full flex-wrap items-center justify-end gap-3;
}

.model-picker__selected {
  @apply text-text mr-auto text-[15px] font-semibold;
  font-variant-numeric: tabular-nums;
}

@media (prefers-reduced-motion: reduce) {
  .model-picker__grid--refreshing {
    transition-duration: 1ms;
  }
}
</style>
