<script lang="ts">
export default {
  name: "ComponentsFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type ComponentQuery } from "@/services/fyAdminApi";
import { useComponentFilters } from "@/admin/composables/useComponentFilters";

const { t } = useI18n();

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    itemTypeCont: filters.value.itemTypeCont,
    componentClassCont: filters.value.componentClassCont,
    manufacturerIdIn: filters.value.manufacturerIdIn || [],
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useComponentFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<ComponentQuery>(prefillFormValues());

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
        translation-key="filters.components.name"
        :no-label="true"
        :clearable="true"
        inline
      />
    </Teleport>

    <ManufacturerFilterGroup
      v-model="form.manufacturerIdIn"
      value-attr="id"
      name="manufacturer"
    />

    <FormInput
      v-model="form.itemTypeCont"
      name="itemType"
      translation-key="filters.components.itemType"
      :clearable="true"
    />

    <FormInput
      v-model="form.componentClassCont"
      name="componentClass"
      translation-key="filters.components.componentClass"
      :clearable="true"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
