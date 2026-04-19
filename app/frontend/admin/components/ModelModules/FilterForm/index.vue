<script lang="ts">
export default {
  name: "ModelModulesFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelModuleQuery } from "@/services/fyAdminApi";
import { useModelModuleFilters } from "@/admin/composables/useModelModuleFilters";

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    moduleHardpointsModelIdEq: filters.value.moduleHardpointsModelIdEq,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useModelModuleFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<ModelModuleQuery>(prefillFormValues());

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
        translation-key="filters.modelModules.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <ModelFilterGroup
      v-model="form.moduleHardpointsModelIdEq"
      name="model"
      value-attr="id"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
