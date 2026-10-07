<script lang="ts">
export default {
  name: "HangarBuybacksFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import {
  BuybackPledgeKindEnum,
  type BuybackPledgeQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const prefillFormValues = (): BuybackPledgeQuery => ({
  nameCont: filters.value.nameCont,
  kindEq: filters.value.kindEq,
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useFilters<BuybackPledgeQuery>({ updateCallback: setupForm });

const form = ref<BuybackPledgeQuery>(prefillFormValues());

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

const kindOptions = computed(() =>
  Object.values(BuybackPledgeKindEnum).map((kind) => ({
    value: kind,
    label: t(`labels.buybacks.kinds.${kind}`),
  })),
);
</script>

<template>
  <form @submit.prevent="filter(form)">
    <FormInput
      v-model="form.nameCont"
      name="nameCont"
      :label="t('labels.buybacks.search')"
      :placeholder="t('labels.buybacks.search')"
      :no-label="true"
      :clearable="true"
    />

    <BaseSelect
      v-model="form.kindEq"
      name="kindEq"
      :options="kindOptions"
      :label="t('labels.buybacks.kind')"
      :searchable="false"
      :paginated="false"
      :no-label="true"
      unsorted
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
