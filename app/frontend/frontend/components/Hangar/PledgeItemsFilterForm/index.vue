<script lang="ts">
export default {
  name: "HangarPledgeItemsFilterForm",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import type { HangarPledgeItemQuery } from "@/services/fyApi";

const { t } = useI18n();

const prefillFormValues = (): HangarPledgeItemQuery => ({
  nameCont: filters.value.nameCont,
  meltableEq: filters.value.meltableEq,
  withValue: filters.value.withValue,
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<HangarPledgeItemQuery>({ updateCallback: setupForm });

const form = ref<HangarPledgeItemQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const { booleanOptions } = useFilterOptions();
</script>

<template>
  <form @submit.prevent="filter(form)">
    <FormInput
      v-model="form.nameCont"
      name="nameCont"
      :label="t('labels.hangarPledgeItems.search')"
      :placeholder="t('labels.hangarPledgeItems.search')"
      :no-label="true"
      :clearable="true"
    />

    <RadioList
      v-model="form.meltableEq"
      :label="t('labels.hangarPledgeItems.meltable')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="meltableEq"
    />

    <FormToggle
      v-model="form.withValue"
      :label="t('labels.hangarPledgeItems.withValue')"
      name="withValue"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
