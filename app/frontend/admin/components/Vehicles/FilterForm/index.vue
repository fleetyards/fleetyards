<script lang="ts">
export default {
  name: "VehiclesFilterForm",
};
</script>

<script lang="ts" setup>
import RadioList from "@/shared/components/base/RadioList/index.vue";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import UserFilterGroup from "@/admin/components/base/UserFilterGroup/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/admin/components/base/ProductionStatusFilterGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type VehicleQuery } from "@/services/fyAdminApi";
import { useVehicleFilters } from "@/admin/composables/useVehicleFilters";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";

const { booleanOptions } = useFilterOptions();

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    searchCont: filters.value.searchCont,
    userUsernameIn: filters.value.userUsernameIn || [],
    modelSlugIn: filters.value.modelSlugIn || [],
    manufacturerIn: filters.value.manufacturerIn || [],
    modelProductionStatusIn: filters.value.modelProductionStatusIn || [],
    loanerEq: filters.value.loanerEq,
    wantedEq: filters.value.wantedEq,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useVehicleFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<VehicleQuery>(prefillFormValues());

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

    <ModelFilterGroup v-model="form.modelSlugIn" name="model" multiple />

    <UserFilterGroup v-model="form.userUsernameIn" name="user" multiple />

    <ManufacturerFilterGroup
      v-model="form.manufacturerIn"
      name="manufacturer"
    />

    <ProductionStatusFilterGroup
      v-model="form.modelProductionStatusIn"
      name="production-status"
    />

    <RadioList
      v-model="form.loanerEq"
      :label="t('labels.filters.vehicles.loaner')"
      :reset-label="t('labels.hide')"
      :options="[
        {
          label: t('labels.show'),
          value: 'true',
        },
        {
          label: t('labels.only'),
          value: 'only',
        },
      ]"
      name="loaner"
    />

    <RadioList
      v-model="form.wantedEq"
      :label="t('labels.filters.vehicles.wanted')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="wanted"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
