<script lang="ts">
export default {
  name: "ModelsFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ManufacturerQuery } from "@/services/fyAdminApi";
import { useManufacturerFilters } from "@/admin/composables/useManufacturerFilters";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";

const { booleanOptions } = useFilterOptions();

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    withModels: filters.value.withModels,
    logoBlank: filters.value.logoBlank,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useManufacturerFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<ManufacturerQuery>(prefillFormValues());

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.nameCont"
        name="search"
        translation-key="filters.manufacturers.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <RadioList
      v-model="form.withModels"
      :label="t('labels.filters.manufacturers.withModels')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="withModels"
    />

    <RadioList
      v-model="form.logoBlank"
      :label="t('labels.filters.manufacturers.logoBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="logoBlank"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
