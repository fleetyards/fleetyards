<script lang="ts">
export default {
  name: "HangarBuybacksFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ModelPickerSelect from "@/frontend/components/Models/PickerSelect/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";
import { useComlink } from "@/shared/composables/useComlink";
import {
  BuybackPledgeKindEnum,
  useHangarBuybackInsuranceTerms,
  type BuybackPledgeQuery,
} from "@/services/fyApi";

const { t } = useI18n();

const prefillFormValues = (): BuybackPledgeQuery => ({
  nameCont: filters.value.nameCont,
  kindEq: filters.value.kindEq,
  priceIn: filters.value.priceIn || [],
  insuranceIn: filters.value.insuranceIn || [],
  priceGteq: filters.value.priceGteq,
  priceLteq: filters.value.priceLteq,
  upgradeFromModelSlugEq: filters.value.upgradeFromModelSlugEq,
  upgradeToModelSlugEq: filters.value.upgradeToModelSlugEq,
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

const { pledgePriceOptions } = useFilterOptions();

const { data: insuranceTerms, refetch: refetchInsuranceTerms } =
  useHangarBuybackInsuranceTerms();

const comlink = useComlink();

let offSyncFinished: (() => void) | undefined;

onMounted(() => {
  offSyncFinished = comlink.on("buyback-sync-finished", () =>
    refetchInsuranceTerms(),
  );
});

onUnmounted(() => {
  offSyncFinished?.();
});

const insuranceLabel = (value: string) => {
  if (value === "lifetime") {
    return t("labels.buybacks.lifetimeInsurance");
  }

  if (value === "none") {
    return t("labels.buybacks.noInsurance");
  }

  return t("labels.buybacks.insuranceMonths", { count: Number(value) });
};

// A term from the URL that the caller no longer has is still offered, so it
// can be seen and cleared.
const insuranceOptions = computed(() => {
  const terms = insuranceTerms.value;

  const values = [
    ...(terms?.lifetime ? ["lifetime"] : []),
    ...(terms?.months || []).map(String),
    ...(terms?.none ? ["none"] : []),
  ];

  const selected = [form.value.insuranceIn || []].flat().map(String);

  return [
    ...values,
    ...selected.filter((value) => !values.includes(value)),
  ].map((value) => ({ value, label: insuranceLabel(value) }));
});

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

    <BaseSelect
      v-model="form.priceIn"
      name="priceIn"
      :options="pledgePriceOptions"
      :label="t('labels.buybacks.priceRange')"
      :multiple="true"
      :no-label="true"
      unsorted
    />

    <BaseSelect
      v-model="form.insuranceIn"
      name="insuranceIn"
      :options="insuranceOptions"
      :label="t('labels.buybacks.insurance')"
      :searchable="false"
      :paginated="false"
      :multiple="true"
      :no-label="true"
      unsorted
    />

    <div class="row">
      <div class="col-6">
        <FormInput
          v-model="form.priceGteq"
          name="priceGteq"
          :type="InputTypesEnum.NUMBER"
          :label="t('labels.buybacks.priceMin')"
          :no-placeholder="true"
        />
      </div>
      <div class="col-6">
        <FormInput
          v-model="form.priceLteq"
          name="priceLteq"
          :type="InputTypesEnum.NUMBER"
          :label="t('labels.buybacks.priceMax')"
          :no-placeholder="true"
        />
      </div>
    </div>

    <ModelPickerSelect
      v-model="form.upgradeFromModelSlugEq"
      name="upgradeFromModelSlugEq"
      :label="t('labels.buybacks.upgradeFrom')"
    />

    <ModelPickerSelect
      v-model="form.upgradeToModelSlugEq"
      name="upgradeToModelSlugEq"
      :label="t('labels.buybacks.upgradeTo')"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
