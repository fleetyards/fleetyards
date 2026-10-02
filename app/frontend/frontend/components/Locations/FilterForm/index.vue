<script lang="ts">
export default {
  name: "LocationsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useLocationFilters } from "@/frontend/composables/useLocationFilters";
import {
  type FilterOption,
  type Location,
  type LocationQuery,
  LocationKindEnum,
  locations as fetchLocations,
  useLocations,
} from "@/services/fyApi";

const { t } = useI18n();

const asList = (value: unknown): string[] => {
  if (Array.isArray(value)) return value as string[];

  return value ? [value as string] : [];
};

const prefillFormValues = (): LocationQuery => ({
  nameCont: filters.value.nameCont,
  kindIn: asList(
    filters.value.kindIn ?? filters.value.kindEq,
  ) as LocationQuery["kindIn"],
  // Folded into `kindIn` above, so a filter the form writes drops it: kept,
  // ransack would intersect the two and an old kind would outlive the select.
  kindEq: undefined,
  systemIdEq: filters.value.systemIdEq,
  parentIdEq: filters.value.parentIdEq,
  shownOnStarmapEq: filters.value.shownOnStarmapEq,
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useLocationFilters(setupForm);

const form = ref<LocationQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

const kinds = computed(() =>
  Object.values(LocationKindEnum).map((value) => ({
    value,
    label: t(`labels.location.kinds.${value}`),
  })),
);

const { data: systemsResult } = useLocations({
  q: { kindEq: LocationKindEnum.SYSTEM },
});

const systems = computed(() =>
  (systemsResult.value?.items ?? []).map((system) => ({
    value: system.id,
    label: system.name ?? system.slug,
  })),
);

// Any place can hold others, so the parent is searched for rather than
// listed: Nyx alone has 306 QV Logistics Stations to page through.
const fetchParentOptions = (params: BaseSelectParams<FilterOption>) => {
  const q: LocationQuery = {};
  if (params.search) q.nameCont = params.search;
  if (params.missing) q.idIn = [params.missing as string];

  return fetchLocations({ page: String(params.page || 1), q });
};

const formatParents = (response: { items: Location[] }) =>
  (response.items || []).map((location) => ({
    label: location.parent?.name
      ? `${location.name} · ${location.parent.name}`
      : (location.name ?? location.slug),
    value: location.id,
  }));

// Three states rather than a checkbox: shown, hidden, and no opinion.
const starmapOptions = computed(() => [
  { value: "true", label: t("labels.filters.locations.shownOnStarmap") },
  { value: "false", label: t("labels.filters.locations.hiddenOnStarmap") },
]);

// Kept as the string the option carries: `useFilters` drops every falsy
// value, so a `false` would be deleted on its way out and "hidden on the map"
// would return everything.
const starmapValue = computed({
  get: () => {
    const value = form.value.shownOnStarmapEq;
    if (value === undefined || value === null) return undefined;

    return String(value);
  },
  set: (value?: string) => {
    form.value = {
      ...form.value,
      shownOnStarmapEq: value as unknown as boolean | undefined,
    };
  },
});
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.nameCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.locations.name"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <BaseSelect
      v-model="form.systemIdEq"
      name="system"
      :options="systems"
      :label="t('labels.filters.locations.system')"
      :no-label="true"
    />

    <BaseSelect
      v-model="form.parentIdEq"
      name="parent"
      :query-fn="fetchParentOptions"
      :query-response-formatter="formatParents"
      :label="t('labels.filters.locations.parent')"
      :no-label="true"
      searchable
      paginated
    />

    <BaseSelect
      v-model="form.kindIn"
      name="kind"
      :options="kinds"
      :label="t('labels.filters.locations.kind')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="starmapValue"
      name="starmap"
      :options="starmapOptions"
      :label="t('labels.filters.locations.starmap')"
      :no-label="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
