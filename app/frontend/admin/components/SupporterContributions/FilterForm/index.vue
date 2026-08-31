<script lang="ts">
export default {
  name: "SupporterContributionsFilterForm",
};
</script>

<script lang="ts" setup>
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import UserSelect from "@/admin/components/base/UserSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type SupporterContributionQuery } from "@/services/fyAdminApi";
import { useSupporterContributionFilters } from "@/admin/composables/useSupporterContributionFilters";
import { useFilterOptions } from "@/shared/composables/useFilterOptions";

const { booleanOptions } = useFilterOptions();

const { t } = useI18n();

// userIdNull is inverted from the reader's point of view: "linked" means the
// column is *not* null.
const linkedOptions = [
  {
    label: t("labels.filters.supporterContributions.linkedOnly"),
    value: "false",
  },
  {
    label: t("labels.filters.supporterContributions.unlinkedOnly"),
    value: "true",
  },
];

const prefillFormValues = () => {
  return {
    nameCont: filters.value.nameCont,
    recurringEq: filters.value.recurringEq,
    anonymousEq: filters.value.anonymousEq,
    startedAtGteq: filters.value.startedAtGteq,
    startedAtLteq: filters.value.startedAtLteq,
    userIdEq: filters.value.userIdEq,
    userIdNull: filters.value.userIdNull,
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, resetFilter, isFilterSelected, filters } =
  useSupporterContributionFilters(setupForm);

const handleSubmit = () => {
  filter(form.value);
};

const form = ref<SupporterContributionQuery>(prefillFormValues());

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
        translation-key="filters.supporterContributions.name"
        no-label
        clearable
        inline
      />
    </Teleport>

    <RadioList
      v-model="form.recurringEq"
      :label="t('labels.filters.supporterContributions.recurring')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="recurringEq"
    />

    <RadioList
      v-model="form.anonymousEq"
      :label="t('labels.filters.supporterContributions.anonymous')"
      :reset-label="t('labels.all')"
      :options="booleanOptions"
      name="anonymousEq"
    />

    <UserSelect
      v-model="form.userIdEq"
      :label="t('labels.filters.supporterContributions.user')"
      :no-label="false"
      :multiple="false"
      value-attr="id"
      name="userIdEq"
    />

    <RadioList
      v-model="form.userIdNull"
      :label="t('labels.filters.supporterContributions.linked')"
      :reset-label="t('labels.all')"
      :options="linkedOptions"
      name="userIdNull"
    />

    <FormDatePicker
      v-model="form.startedAtGteq"
      translation-key="filters.supporterContributions.startedAtGteq"
      name="startedAtGteq"
    />

    <FormDatePicker
      v-model="form.startedAtLteq"
      translation-key="filters.supporterContributions.startedAtLteq"
      name="startedAtLteq"
    />

    <br />
    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fa-light fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
