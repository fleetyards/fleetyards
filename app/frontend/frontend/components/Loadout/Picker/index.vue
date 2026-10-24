<script lang="ts">
export default {
  name: "LoadoutPicker",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import ListToolbar from "@/shared/components/base/ListToolbar/index.vue";
import type { BaseTableCol } from "@/shared/components/base/Table/types";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import Loader from "@/shared/components/Loader/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import type {
  LoadoutPickerFacet,
  LoadoutPickerOption,
  LoadoutPickerSort,
} from "@/frontend/components/Loadout/Picker/types";

type Props = {
  // What is being filled, e.g. the socket's label.
  title: string;
  options: LoadoutPickerOption[];
  // What the socket holds now.
  selectedId?: string;
  sorts?: LoadoutPickerSort[];
  // Offers a choice that leaves the socket empty.
  clearable?: boolean;
  // The options are on their way: none are shown, only a spinner, so a list
  // that belongs to another socket never stands in for them.
  loading?: boolean;
  facets?: LoadoutPickerFacet[];
  // Fills its containing block instead of sitting in the page as a panel, for
  // a phone, where there is no room beside the sockets.
  sheet?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  selectedId: undefined,
  sorts: () => [],
  clearable: true,
  loading: false,
  facets: () => [],
  sheet: false,
});

const emit = defineEmits<{
  pick: [optionId: string | null];
  // The option under the pointer or focus; `null` is the empty choice.
  preview: [optionId: string | null];
  // The pointer or focus has left the list: back to what is picked.
  previewEnd: [];
  close: [];
}>();

const { t } = useI18n();

const { supported: webpSupported } = useWebpCheck();

const imageFor = (option: LoadoutPickerOption) =>
  option.image || (webpSupported.value ? fallbackImage : fallbackImageJpg);

const search = ref("");

const ownedOnly = ref(false);

const stockOnly = ref(false);

const manufacturer = ref<string | null>(null);

const NAME_SORT = "name";

// The caller's first figure, the way it reads best, else by name.
const defaultSort = computed(() => {
  const first = props.sorts[0];
  if (!first) return `${NAME_SORT} asc`;

  return `${first.key} ${first.ascending ? "asc" : "desc"}`;
});

// What the sort bar picked; undefined is the default. Kept here rather than in
// the URL, which belongs to the page under the modal.
const sort = ref<string>();

// Counted like the hangar's category chips, which is what tells these apart
// from a label as filters.
const ownedCount = computed(
  () => props.options.filter((option) => option.owned).length,
);

const stockCount = computed(
  () => props.options.filter((option) => option.stock).length,
);

const manufacturers = computed(() =>
  [
    ...new Set(
      props.options
        .map((option) => option.manufacturer)
        .filter((name): name is string => !!name),
    ),
  ].sort((a, b) => a.localeCompare(b)),
);

const manufacturerOptions = computed(() =>
  manufacturers.value.map((name) => ({ label: name, value: name })),
);

const sortColumns = computed<BaseTableCol<LoadoutPickerOption>[]>(() => [
  {
    name: NAME_SORT,
    label: t("labels.loadoutPicker.sortName"),
    sortable: true,
  },
  ...props.sorts.map((entry) => ({
    name: entry.key,
    label: entry.label,
    sortable: true,
  })),
]);

const matchesSearch = (option: LoadoutPickerOption, term: string) =>
  !term ||
  option.name.toLowerCase().includes(term) ||
  !!option.manufacturer?.toLowerCase().includes(term);

// Owned and stock widen each other rather than narrow: either is something
// the ship can fit without buying it.
const matchesOwnership = (option: LoadoutPickerOption) => {
  if (!ownedOnly.value && !stockOnly.value) return true;

  return (
    (ownedOnly.value && !!option.owned) || (stockOnly.value && !!option.stock)
  );
};

// The filters behind the filter button, a chip per value. A facet whose
// options all share one value narrows nothing and is left out.
const filtersOpen = ref(false);

const facetPicks = ref<Record<string, string[]>>({});

const facetGroups = computed(() =>
  props.facets
    .map((facet) => {
      const counts = new Map<string, number>();
      props.options.forEach((option) => {
        const value = option.facets?.[facet.key];
        if (value) counts.set(value, (counts.get(value) ?? 0) + 1);
      });

      return {
        ...facet,
        values: [...counts]
          .map(([value, count]) => ({ value, count }))
          .sort((a, b) => a.value.localeCompare(b.value)),
      };
    })
    .filter((facet) => facet.values.length > 1),
);

const facetPickCount = computed(
  () =>
    Object.values(facetPicks.value).flat().length +
    (manufacturer.value ? 1 : 0),
);

const toggleFacet = (key: string, value: string) => {
  const picked = facetPicks.value[key] ?? [];
  facetPicks.value = {
    ...facetPicks.value,
    [key]: picked.includes(value)
      ? picked.filter((entry) => entry !== value)
      : [...picked, value],
  };
};

const facetPicked = (key: string, value: string) =>
  !!facetPicks.value[key]?.includes(value);

// Values of one facet widen each other; facets narrow each other.
const matchesFacets = (option: LoadoutPickerOption) =>
  Object.entries(facetPicks.value).every(
    ([key, values]) =>
      !values.length || values.includes(option.facets?.[key] ?? ""),
  );

const compare = (a: LoadoutPickerOption, b: LoadoutPickerOption) => {
  const [key, direction] = (sort.value || defaultSort.value).split(" ");
  const sign = direction === "desc" ? -1 : 1;

  if (key === NAME_SORT) return sign * a.name.localeCompare(b.name);

  const valueA = a.sortValues?.[key];
  const valueB = b.sortValues?.[key];

  // An option without the figure sorts last either way round.
  if (valueA === undefined && valueB === undefined) {
    return a.name.localeCompare(b.name);
  }
  if (valueA === undefined) return 1;
  if (valueB === undefined) return -1;

  return sign * (valueA - valueB) || a.name.localeCompare(b.name);
};

const visibleOptions = computed(() => {
  const term = search.value.trim().toLowerCase();

  return props.options
    .filter(
      (option) =>
        matchesSearch(option, term) &&
        matchesFacets(option) &&
        matchesOwnership(option) &&
        (!manufacturer.value || option.manufacturer === manufacturer.value),
    )
    .sort(compare);
});

const filtered = computed(
  () => visibleOptions.value.length !== props.options.length,
);

const resetFilters = () => {
  search.value = "";
  ownedOnly.value = false;
  stockOnly.value = false;
  manufacturer.value = null;
  facetPicks.value = {};
};

const root = ref<HTMLElement>();

const list = ref<HTMLElement>();

// Focus moving between options keeps the preview; only leaving the list ends it.
const onFocusOut = (event: FocusEvent) => {
  if (!list.value?.contains(event.relatedTarget as Node | null)) {
    emit("previewEnd");
  }
};

/*
 * A press anywhere else closes the picker, except on a socket: that one switches
 * what the picker fills, and closing first would only reopen it a moment later.
 * Captured, so a control that stops the event on its way up still counts.
 */
const onDocumentPointerdown = (event: PointerEvent) => {
  const target = event.target as Element | null;
  if (!target || root.value?.contains(target)) return;
  if (target.closest?.(".loadout-socket")) return;

  emit("close");
};

onMounted(() => {
  document.addEventListener("pointerdown", onDocumentPointerdown, true);
});

onBeforeUnmount(() => {
  document.removeEventListener("pointerdown", onDocumentPointerdown, true);
});

const onKeydown = (event: KeyboardEvent) => {
  // A control inside that answered Escape itself, such as an open dropdown,
  // keeps it: the press closed that, not the picker.
  if (event.key !== "Escape" || event.defaultPrevented) return;

  event.stopPropagation();
  emit("close");
};

const focusSearch = () => {
  root.value?.querySelector<HTMLInputElement>("input")?.focus();
};

const focus = () => {
  root.value?.focus();
};

defineExpose({ focus, focusSearch, resetFilters });

const accessibleName = (option: LoadoutPickerOption) =>
  [
    option.name,
    option.manufacturer,
    option.owned ? t("labels.loadoutPicker.owned") : undefined,
    option.stock ? t("labels.loadoutPicker.stock") : undefined,
    option.figure,
    option.delta?.label,
  ]
    .filter(Boolean)
    .join(", ");
</script>

<template>
  <section
    ref="root"
    class="loadout-picker"
    :class="{ 'loadout-picker--sheet': sheet }"
    data-test="loadout-picker"
    :aria-label="title"
    tabindex="-1"
    @keydown="onKeydown"
  >
    <header class="loadout-picker__header">
      <h4 class="loadout-picker__title">{{ title }}</h4>
      <button
        type="button"
        class="loadout-picker__close"
        :aria-label="t('labels.loadoutPicker.close')"
        data-test="loadout-picker-close"
        @click="emit('close')"
      >
        <i class="fa-light fa-times" aria-hidden="true" />
      </button>
    </header>

    <div class="loadout-picker__controls">
      <!-- The ownership filters sit beside the search: like it, they narrow
           the list in one press. -->
      <div class="loadout-picker__search-row">
        <FormInput
          v-model="search"
          name="loadout-picker-search"
          class="loadout-picker__search"
          :label="t('labels.loadoutPicker.search')"
          :placeholder="t('labels.loadoutPicker.search')"
          icon="fa-light fa-magnifying-glass"
          data-test="loadout-picker-search"
          standalone
          no-label
          clearable
        />
        <Chip
          v-if="ownedCount"
          :state="ownedOnly ? ChipStatesEnum.INCLUDED : ChipStatesEnum.NEUTRAL"
          :count="ownedCount"
          data-test="loadout-picker-owned"
          @toggle="ownedOnly = !ownedOnly"
        >
          {{ t("labels.loadoutPicker.owned") }}
        </Chip>
        <Chip
          v-if="stockCount"
          :state="stockOnly ? ChipStatesEnum.INCLUDED : ChipStatesEnum.NEUTRAL"
          :count="stockCount"
          data-test="loadout-picker-stock"
          @toggle="stockOnly = !stockOnly"
        >
          {{ t("labels.loadoutPicker.stock") }}
        </Chip>
        <Btn
          v-if="facetGroups.length || manufacturers.length > 1"
          class="loadout-picker__filter-toggle"
          :active="filtersOpen"
          :aria-expanded="filtersOpen"
          v-tooltip="t('labels.filter')"
          :aria-label="t('labels.filter')"
          data-test="loadout-picker-filters-toggle"
          @click="filtersOpen = !filtersOpen"
        >
          <i class="fa-light fa-filter" aria-hidden="true" />
          <span
            v-if="facetPickCount"
            class="loadout-picker__filter-count"
            data-test="loadout-picker-filters-count"
          >
            {{ facetPickCount }}
          </span>
        </Btn>
      </div>

      <div
        v-if="filtersOpen"
        class="loadout-picker__filters"
        data-test="loadout-picker-filters"
      >
        <BaseSelect
          v-if="manufacturers.length > 1"
          v-model="manufacturer"
          name="loadout-picker-manufacturer"
          class="loadout-picker__select"
          :options="manufacturerOptions"
          :label="t('labels.loadoutPicker.manufacturer')"
          :search-label="t('labels.loadoutPicker.manufacturer')"
          data-test="loadout-picker-manufacturer"
          searchable
          nullable
          no-label
        />
        <div
          v-for="facet in facetGroups"
          :key="facet.key"
          class="loadout-picker__facet"
          :data-test="`loadout-picker-facet-${facet.key}`"
        >
          <span class="loadout-picker__facet-label">{{ facet.label }}</span>
          <div class="loadout-picker__facet-values">
            <Chip
              v-for="entry in facet.values"
              :key="entry.value"
              :state="
                facetPicked(facet.key, entry.value)
                  ? ChipStatesEnum.INCLUDED
                  : ChipStatesEnum.NEUTRAL
              "
              :count="entry.count"
              @toggle="toggleFacet(facet.key, entry.value)"
            >
              {{ entry.value }}
            </Chip>
          </div>
        </div>
      </div>

      <div class="loadout-picker__sort-row">
        <ListToolbar
          v-model:sort="sort"
          class="loadout-picker__sort"
          :columns="sortColumns"
          :default-sort="defaultSort"
          data-test="loadout-picker-sort"
          local
        />
      </div>
    </div>

    <!-- The count floats over the list's top corner rather than taking a
         line of the controls, where it wrapped beside the sort chips. -->
    <div class="loadout-picker__list">
      <p class="loadout-picker__count" data-test="loadout-picker-count">
        <template v-if="filtered">
          {{
            t("labels.loadoutPicker.count", {
              count: visibleOptions.length,
              total: options.length,
            })
          }}
          <button
            type="button"
            class="loadout-picker__reset"
            data-test="loadout-picker-reset"
            @click="resetFilters"
          >
            {{ t("labels.loadoutPicker.reset") }}
          </button>
        </template>
        <template v-else>
          {{ t("labels.loadoutPicker.total", { count: options.length }) }}
        </template>
      </p>
      <ul
        ref="list"
        class="loadout-picker__options"
        data-test="loadout-picker-options"
        @mouseleave="emit('previewEnd')"
        @focusout="onFocusOut"
      >
        <li v-if="clearable">
          <button
            type="button"
            class="loadout-picker__option loadout-picker__option--empty"
            :class="{ 'loadout-picker__option--selected': !selectedId }"
            :aria-pressed="!selectedId"
            data-test="loadout-picker-empty"
            @mouseenter="emit('preview', null)"
            @focusin="emit('preview', null)"
            @click="emit('pick', null)"
          >
            <span class="loadout-picker__image loadout-picker__image--glyph">
              <i class="fa-duotone fa-layer-minus" aria-hidden="true" />
            </span>
            <span class="loadout-picker__body">
              <span class="loadout-picker__name">
                {{ t("labels.loadoutPicker.leaveEmpty") }}
              </span>
            </span>
            <i
              v-if="!selectedId"
              class="fa-solid fa-circle-check loadout-picker__check"
              aria-hidden="true"
            />
          </button>
        </li>
        <li
          v-for="(option, index) in loading ? [] : visibleOptions"
          :key="option.id"
          class="loadout-picker__entry"
          :style="{ '--entry-index': Math.min(index, 12) }"
        >
          <button
            type="button"
            class="loadout-picker__option"
            :class="{
              'loadout-picker__option--selected': option.id === selectedId,
            }"
            :aria-pressed="option.id === selectedId"
            :aria-label="accessibleName(option)"
            data-test="loadout-picker-option"
            @mouseenter="emit('preview', option.id)"
            @focusin="emit('preview', option.id)"
            @click="emit('pick', option.id)"
          >
            <img
              :src="imageFor(option)"
              alt=""
              class="loadout-picker__image"
              loading="lazy"
            />
            <span class="loadout-picker__body">
              <span class="loadout-picker__name">{{ option.name }}</span>
              <span
                v-if="option.manufacturer || option.description"
                class="loadout-picker__meta"
              >
                {{
                  [option.manufacturer, option.description]
                    .filter(Boolean)
                    .join(" · ")
                }}
              </span>
            </span>
            <span class="loadout-picker__badges">
              <Pill v-if="option.owned" :variant="PillVariantsEnum.SUCCESS">
                {{ t("labels.loadoutPicker.owned") }}
              </Pill>
              <Pill
                v-else-if="option.stock"
                :variant="PillVariantsEnum.NEUTRAL"
              >
                {{ t("labels.loadoutPicker.stock") }}
              </Pill>
            </span>
            <span
              v-if="option.figure || option.delta"
              class="loadout-picker__figure"
            >
              <span v-if="option.figure">{{ option.figure }}</span>
              <span
                v-if="option.delta"
                class="loadout-picker__delta"
                :class="`loadout-picker__delta--${option.delta.tone}`"
                data-test="loadout-picker-delta"
              >
                {{ option.delta.label }}
              </span>
            </span>
            <i
              v-if="option.id === selectedId"
              class="fa-solid fa-circle-check loadout-picker__check"
              aria-hidden="true"
            />
          </button>
        </li>
        <li
          v-if="loading"
          class="loadout-picker__loading"
          data-test="loadout-picker-loading"
        >
          <Loader loading inline immediate />
        </li>
        <li
          v-else-if="!visibleOptions.length"
          class="loadout-picker__no-matches"
          data-test="loadout-picker-no-matches"
        >
          {{ t("labels.loadoutPicker.noMatches") }}
        </li>
      </ul>
    </div>

    <div v-if="$slots.comparison" class="loadout-picker__comparison">
      <slot name="comparison" />
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
