<script lang="ts">
export default {
  name: "VehiclesFilterForm",
};
</script>

<script lang="ts" setup>
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import ModelSelect from "@/admin/components/base/ModelSelect/index.vue";
import UserSelect from "@/admin/components/base/UserSelect/index.vue";
import ManufacturerSelect from "@/admin/components/base/ManufacturerSelect/index.vue";
import ProductionStatusSelect from "@/admin/components/base/ProductionStatusSelect/index.vue";
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
        :size="InputSizesEnum.MEDIUM"
        v-model="form.searchCont"
        name="search"
        translation-key="filters.models.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <ModelSelect v-model="form.modelSlugIn" name="model" multiple />

    <UserSelect v-model="form.userUsernameIn" name="user" multiple />

    <ManufacturerSelect v-model="form.manufacturerIn" name="manufacturer" />

    <ProductionStatusSelect
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
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
