<script lang="ts">
export default {
  name: "CompareModelsForm",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import ModelSelect from "@/frontend/components/base/ModelSelect/index.vue";
import { BaseSelectSizesEnum } from "@/shared/components/base/Select/types";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { uniq as uniqArray } from "@/shared/utils/Array";
import { ComponentExposed } from "vue-component-type-helpers";

const { t } = useI18n();

// Matches CompareImage::MAX_SHARE_MODELS — beyond that a comparison cannot be shared.
const MAX_MODELS = 8;

const prefillFormValues = () => ({
  models: filters.value.models || [],
});

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, filters } = useCompareModelFilters(setupForm);

const form = ref<{ models: string[] }>(prefillFormValues());

const selectDisabled = computed(() => form.value.models.length >= MAX_MODELS);

const disabledTooltip = computed(() =>
  selectDisabled.value ? t("labels.compare.enough") : undefined,
);

const modelSelect = ref<ComponentExposed<typeof ModelSelect>>();

const handleChange = (model: string) => {
  if (model) {
    // Appended, not sorted: the query carries slugs and the table orders its
    // columns by ship name, so sorting here only decided which slug order the URL
    // happened to carry.
    form.value.models = [...(form.value.models || []), model].filter(uniqArray);

    filter(form.value);
  }

  modelSelect.value?.clear();
};
</script>

<template>
  <div class="compare-form">
    <ModelSelect
      ref="modelSelect"
      v-tooltip="disabledTooltip"
      :disabled="selectDisabled"
      :size="BaseSelectSizesEnum.MEDIUM"
      name="new-model"
      @update:model-value="handleChange"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
