<script lang="ts">
export default {
  name: "AdminFeedbackFilterForm",
};
</script>

<script lang="ts" setup>
import { InputSizesEnum } from "@/shared/components/base/FormInput/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import { featureLabel } from "@/shared/utils/BetaFeatures";
import { type FeedbackQuery, FeedbackStateEnum } from "@/services/fyAdminApi";
import { FeatureFlagName } from "@/services/fyApi";

const { t } = useI18n();

const prefillFormValues = (): FeedbackQuery => ({
  messageCont: filters.value.messageCont,
  aasmStateEq: filters.value.aasmStateEq,
  featureNameEq: filters.value.featureNameEq,
});

const { filter, filters } = useFilters<FeedbackQuery>({
  updateCallback: () => {
    form.value = prefillFormValues();
  },
});

const form = ref<FeedbackQuery>(prefillFormValues());

const stateOptions = Object.values(FeedbackStateEnum).map((state) => ({
  value: state,
  label: t(`feedback.admin.states.${state}`),
}));

const featureOptions = Object.values(FeatureFlagName)
  .sort()
  .map((feature) => ({ value: feature, label: featureLabel(feature) }));

watch(
  () => form.value,
  () => {
    filter(form.value);
  },
  { deep: true },
);
</script>

<template>
  <form @submit.prevent="filter(form)">
    <Teleport to="#header-left">
      <FormInput
        v-model="form.messageCont"
        :size="InputSizesEnum.MEDIUM"
        name="search"
        :label="t('feedback.admin.search')"
        :placeholder="t('feedback.admin.search')"
        no-label
        clearable
        inline
      />
    </Teleport>
    <BaseSelect
      v-model="form.aasmStateEq"
      name="state"
      :label="t('feedback.admin.state')"
      :options="stateOptions"
    />
    <BaseSelect
      v-model="form.featureNameEq"
      name="feature"
      :label="t('feedback.admin.feature')"
      :options="featureOptions"
      searchable
    />
  </form>
</template>
