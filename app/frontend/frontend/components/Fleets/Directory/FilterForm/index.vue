<script lang="ts">
export default {
  name: "FleetDirectoryFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetDirectoryFilters } from "@/frontend/composables/useFleetDirectoryFilters";
import { useFleetProfileLabels } from "@/frontend/composables/useFleetProfileLabels";
import { TIMEZONE_OPTIONS } from "@/shared/utils/Timezones";
import { type FleetDirectoryQuery } from "@/services/fyApi";

const { t } = useI18n();

// A single value in the URL comes back from `route.query` as a string, not an
// array, so every multi-select is handed a list whatever the URL held.
const asList = <T,>(value: unknown): T[] => {
  if (Array.isArray(value)) return value as T[];

  return value ? [value as T] : [];
};

// Booleans ride in the query as strings. Only "on" filters: an unticked toggle
// means "either", not "not recruiting".
const asTrue = (value: unknown): boolean | undefined =>
  value === true || value === "true" ? true : undefined;

const asNumber = (value: unknown): number | undefined => {
  const number = Number(value);

  return value === undefined || value === "" || Number.isNaN(number)
    ? undefined
    : number;
};

const prefillFormValues = (): FleetDirectoryQuery => ({
  search: filters.value.search,
  memberCountGteq: asNumber(filters.value.memberCountGteq),
  alignmentIn: asList(filters.value.alignmentIn),
  activityIn: asList(filters.value.activityIn),
  languageIn: asList(filters.value.languageIn),
  commitmentIn: asList(filters.value.commitmentIn),
  defaultTimezoneIn: asList(filters.value.defaultTimezoneIn),
  recruitingEq: asTrue(filters.value.recruitingEq),
  roleplayEq: asTrue(filters.value.roleplayEq),
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useFleetDirectoryFilters(setupForm);

const form = ref<FleetDirectoryQuery>(prefillFormValues());

watch(
  () => form.value,
  () =>
    filter({
      ...form.value,
      recruitingEq: form.value.recruitingEq || undefined,
      roleplayEq: form.value.roleplayEq || undefined,
    }),
  { deep: true },
);

const handleSubmit = () => {
  filter(form.value);
};

const {
  activityOptions,
  alignmentOptions,
  commitmentOptions,
  languageOptions,
} = useFleetProfileLabels();

const timezoneOptions = TIMEZONE_OPTIONS.map((timezone) => ({
  value: timezone.value,
  label: timezone.label,
}));
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.search"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        translation-key="filters.fleetDirectory.search"
        :no-label="true"
        :clearable="true"
      />
    </Teleport>

    <FormInput
      v-model="form.memberCountGteq"
      name="memberCountGteq"
      type="number"
      translation-key="filters.fleetDirectory.memberCountGteq"
      :no-label="true"
      :clearable="true"
    />

    <BaseSelect
      v-model="form.activityIn"
      name="activityIn"
      :options="activityOptions"
      :label="t('labels.filters.fleetDirectory.activity')"
      :no-label="true"
      multiple
    />

    <BaseSelect
      v-model="form.languageIn"
      name="languageIn"
      :options="languageOptions"
      :label="t('labels.filters.fleetDirectory.language')"
      :no-label="true"
      searchable
      multiple
    />

    <BaseSelect
      v-model="form.alignmentIn"
      name="alignmentIn"
      :options="alignmentOptions"
      :label="t('labels.filters.fleetDirectory.alignment')"
      :no-label="true"
      unsorted
      multiple
    />

    <BaseSelect
      v-model="form.commitmentIn"
      name="commitmentIn"
      :options="commitmentOptions"
      :label="t('labels.filters.fleetDirectory.commitment')"
      :no-label="true"
      unsorted
      multiple
    />

    <BaseSelect
      v-model="form.defaultTimezoneIn"
      name="defaultTimezoneIn"
      :options="timezoneOptions"
      :label="t('labels.filters.fleetDirectory.timezone')"
      :no-label="true"
      searchable
      unsorted
      multiple
    />

    <FormToggle
      v-model="form.recruitingEq"
      name="recruitingEq"
      :label="t('labels.filters.fleetDirectory.recruiting')"
    />

    <FormToggle
      v-model="form.roleplayEq"
      name="roleplayEq"
      :label="t('labels.filters.fleetDirectory.roleplay')"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
