<script lang="ts">
export default {
  name: "FleetsFilterForm",
};
</script>

<script lang="ts" setup>
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type FleetQuery } from "@/services/fyAdminApi";
import { useFilters } from "@/shared/composables/useFilters";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";

const { t } = useI18n();

const { booleanOptions } = useFilterOptions();

// A number read back from the URL is a string.
const asNumber = (value: unknown): number | undefined => {
  const number = Number(value);

  return value === undefined ||
    value === null ||
    value === "" ||
    Number.isNaN(number)
    ? undefined
    : number;
};

const prefillFormValues = (): FleetQuery => {
  return {
    nameCont: filters.value.nameCont,
    fidCont: filters.value.fidCont,
    memberCountGteq: asNumber(filters.value.memberCountGteq),
    memberCountLteq: asNumber(filters.value.memberCountLteq),
    rsiVerifiedEq: filters.value.rsiVerifiedEq,
    publicFleetEq: filters.value.publicFleetEq,
    recruitingEq: filters.value.recruitingEq,
    createdOnGteq: filters.value.createdOnGteq,
    createdOnLteq: filters.value.createdOnLteq,
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
        :size="InputSizesEnum.MEDIUM"
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

    <FormInput
      v-model="form.memberCountGteq"
      name="memberCountGteq"
      type="number"
      translation-key="filters.fleets.memberCountGteq"
      :clearable="true"
    />

    <FormInput
      v-model="form.memberCountLteq"
      name="memberCountLteq"
      type="number"
      translation-key="filters.fleets.memberCountLteq"
      :clearable="true"
    />

    <RadioList
      v-model="form.rsiVerifiedEq"
      :label="t('labels.filters.fleets.rsiVerified')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="rsiVerifiedEq"
    />

    <RadioList
      v-model="form.publicFleetEq"
      :label="t('labels.filters.fleets.publicFleet')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="publicFleetEq"
    />

    <RadioList
      v-model="form.recruitingEq"
      :label="t('labels.filters.fleets.recruiting')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="recruitingEq"
    />

    <FormDatePicker
      v-model="form.createdOnGteq"
      translation-key="filters.fleets.createdOnGteq"
      name="createdOnGteq"
    />

    <FormDatePicker
      v-model="form.createdOnLteq"
      translation-key="filters.fleets.createdOnLteq"
      name="createdOnLteq"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
