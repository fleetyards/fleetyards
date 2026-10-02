<script lang="ts">
export default {
  name: "AdminLocationsFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useLocationFilters } from "@/admin/composables/useLocationFilters";
import { type LocationQuery, LocationKindEnum } from "@/services/fyAdminApi";

const { t } = useI18n();

const prefillFormValues = (): LocationQuery => ({
  nameCont: filters.value.nameCont,
  scKeyCont: filters.value.scKeyCont,
  kindEq: filters.value.kindEq,
  shownOnStarmapEq: filters.value.shownOnStarmapEq,
  currentVersion: filters.value.currentVersion,
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

const kinds = computed(() =>
  Object.values(LocationKindEnum).map((value) => ({
    value,
    label: t(`labels.location.kinds.${value}`),
  })),
);

// Kept as the string each option carries: `useFilters` drops every falsy
// value, so a `false` would be deleted on its way out.
const tristate = (key: "shownOnStarmapEq" | "currentVersion") =>
  computed({
    get: () => {
      const value = form.value[key];
      if (value === undefined || value === null) return undefined;

      return String(value);
    },
    set: (value?: string) => {
      form.value = {
        ...form.value,
        [key]: value as unknown as boolean | undefined,
      };
    },
  });

const starmapValue = tristate("shownOnStarmapEq");
const currentVersionValue = tristate("currentVersion");

const yesNo = (yes: string, no: string) =>
  computed(() => [
    { value: "true", label: t(yes) },
    { value: "false", label: t(no) },
  ]);

const starmapOptions = yesNo(
  "labels.filters.locations.shownOnStarmap",
  "labels.filters.locations.hiddenOnStarmap",
);

const currentVersionOptions = yesNo(
  "labels.admin.missions.filters.currentBuild",
  "labels.admin.missions.filters.anyBuild",
);
</script>

<template>
  <form @submit.prevent="filter(form)">
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

    <!-- The record key is how a place is found again in the export, and what
         the overrides file names. -->
    <FormInput
      v-model="form.scKeyCont"
      name="scKey"
      :label="t('labels.admin.locations.scKey')"
      :clearable="true"
    />

    <BaseSelect
      v-model="form.kindEq"
      name="kind"
      :options="kinds"
      :label="t('labels.filters.locations.kind')"
      :no-label="true"
    />

    <BaseSelect
      v-model="starmapValue"
      name="starmap"
      :options="starmapOptions"
      :label="t('labels.filters.locations.starmap')"
      :no-label="true"
    />

    <BaseSelect
      v-model="currentVersionValue"
      name="currentVersion"
      :options="currentVersionOptions"
      :label="t('labels.admin.missions.filters.build')"
      :no-label="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
