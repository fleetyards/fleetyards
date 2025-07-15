<script lang="ts">
export default {
  name: "CompareModelsForm",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import Starship42Btn from "@/frontend/components/Starship42Btn/index.vue";
import ModelFilterGroup from "@/frontend/components/base/ModelFilterGroup/index.vue";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { type Model } from "@/services/fyApi";
import { uniq as uniqArray } from "@/shared/utils/Array";
import { ComponentExposed } from "vue-component-type-helpers";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const erkulUrl = computed(() => {
  return "https://www.erkul.games/calculator";
});

const spviewerUrl = computed(() => {
  return `https://www.spviewer.eu/compare?ship=${scIdentifiers.value.join("&ship=")}`;
});

const selectDisabled = computed(() => {
  return form.value.models.length > 7;
});

const disabledTooltip = computed(() => {
  if (selectDisabled.value) {
    return t("labels.compare.enough");
  }

  return undefined;
});

const scIdentifiers = computed(() => {
  return props.models.map((model) => model.scIdentifier);
});

const prefillFormValues = () => {
  return {
    models: filters.value.models || [],
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, filters } = useCompareModelFilters(setupForm);

const form = ref<{ models: string[] }>(prefillFormValues());

// const newModel = ref<string>();

// watch(
//   () => newModel.value,
//   () => {
//     if (newModel.value) {
//       form.value.models = [...(form.value.models || []), newModel.value]
//         .filter(uniqArray)
//         .sort();

//       filter(form.value);
//     }
//     newModel.value = undefined;
//   },
// );

const modelFilterGroup = ref<ComponentExposed<typeof ModelFilterGroup>>();

const handleChange = (model: string) => {
  if (model) {
    form.value.models = [...(form.value.models || []), model]
      .filter(uniqArray)
      .sort();

    filter(form.value);
  }

  modelFilterGroup.value?.clear();
};
</script>

<template>
  <div class="compare-form">
    <ModelFilterGroup
      ref="modelFilterGroup"
      v-tooltip="disabledTooltip"
      :disabled="selectDisabled"
      name="new-model"
      @update:model-value="handleChange"
    />
    <Btn :href="erkulUrl" block class="erkul-link">
      <i />
      {{ t("labels.hardpoints.erkul") }}
    </Btn>
    <Btn
      v-tooltip="t('labels.hardpoints.spviewerTitle')"
      :href="spviewerUrl"
      block
      class="spviewer-link"
    >
      <i />
      {{ t("labels.hardpoints.spviewer") }}
    </Btn>
    <Starship42Btn :items="models" with-icon block inline />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
