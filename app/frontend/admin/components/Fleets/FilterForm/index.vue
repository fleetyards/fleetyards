<script lang="ts">
export default {
  name: "FleetsFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type FleetQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    fidCont: filters.value.fidCont,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<FleetQuery>({
    updateCallback: setupForm,
  });

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<FleetQuery>(prefillFormValues());

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
        translation-key="filters.fleets.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <FormInput
      v-model="form.fidCont"
      name="fid"
      translation-key="filters.fleets.fid"
      :clearable="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
