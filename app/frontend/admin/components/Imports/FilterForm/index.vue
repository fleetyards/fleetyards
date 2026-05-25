<script lang="ts">
export default {
  name: "ImportsFilterForm",
};
</script>

<script lang="ts" setup>
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ImportQuery,
  ImportStatusEnum,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const formatTypeLabel = (type: string) =>
  type
    .replace("Imports::", "")
    .replace("::", " ")
    .replace(/([A-Z])/g, " $1")
    .replace(/^ /, "")
    .trim();

const typeOptions = Object.values(ImportTypeEnum).map((value) => ({
  label: formatTypeLabel(value),
  value,
}));

const statusOptions = Object.values(ImportStatusEnum).map((value) => ({
  label: t(`labels.imports.statuses.${value}`),
  value,
}));

const prefillFormValues = (): ImportQuery => ({
  typeIn: filters.value.typeIn || [],
  aasmStateIn: filters.value.aasmStateIn || [],
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<ImportQuery>({
    updateCallback: setupForm,
  });

const form = ref<ImportQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent>
    <FilterGroup
      v-model="form.typeIn"
      :label="t('labels.imports.type')"
      :options="typeOptions"
      :multiple="true"
      name="type"
    />
    <FilterGroup
      v-model="form.aasmStateIn"
      :label="t('labels.imports.status')"
      :options="statusOptions"
      :multiple="true"
      name="status"
    />
    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
