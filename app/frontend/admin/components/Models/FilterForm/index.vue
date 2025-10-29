<script lang="ts">
export default {
  name: "ModelsFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/admin/components/base/ProductionStatusFilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelQuery } from "@/services/fyAdminApi";
import { useModelFilters } from "@/admin/composables/useModelFilters";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { useSessionStore } from "@/admin/stores/session";

const { booleanOptions } = useFilterOptions();

const { t } = useI18n();

const sessionStore = useSessionStore();

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
    nameCont: filters.value.nameCont,
    manufacturerIn: filters.value.manufacturerIn || [],
    productionStatusIn: filters.value.productionStatusIn || [],
    scIdentifierBlank: filters.value.scIdentifierBlank,
    fleetchartImageBlank: filters.value.fleetchartImageBlank,
    holoBlank: filters.value.holoBlank,
    topViewColoredBlank: filters.value.topViewColoredBlank,
    frontViewBlank: filters.value.frontViewBlank,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useModelFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<ModelQuery>(prefillFormValues());

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
        v-model="form.searchCont"
        name="search"
        translation-key="filters.models.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <ManufacturerFilterGroup
      v-if="sessionStore.hasAccessTo('manufacturers')"
      v-model="form.manufacturerIn"
      name="manufacturer"
    />

    <ProductionStatusFilterGroup
      v-model="form.productionStatusIn"
      name="production-status"
    />

    <RadioList
      v-model="form.fleetchartImageBlank"
      :label="t('labels.filters.models.fleetchartImageBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="fleetchartImageBlank"
    />

    <RadioList
      v-model="form.holoBlank"
      :label="t('labels.filters.models.holoBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="holoBlank"
    />

    <RadioList
      v-model="form.frontViewBlank"
      :label="t('labels.filters.models.frontViewBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="frontViewBlank"
    />

    <RadioList
      v-model="form.topViewColoredBlank"
      :label="t('labels.filters.models.topViewColoredBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="topViewColoredBlank"
    />

    <RadioList
      v-model="form.scIdentifierBlank"
      :label="t('labels.filters.models.scIdentifierBlank')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="scIdentifierBlank"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
