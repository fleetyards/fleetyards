<script lang="ts">
export default {
  name: "ModelSelect",
};
</script>

<script lang="ts" setup>
import { ComponentExposed } from "vue-component-type-helpers";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ModelQuery,
  type ModelOptions,
  type ModelOption,
} from "@/services/fyApi";
import BaseSelect, {
  type BaseSelectParams,
  type ValueType,
} from "@/shared/components/base/Select/index.vue";
import { BaseSelectSizesEnum } from "@/shared/components/base/Select/types";
import { modelOptions as fetchModelOptions } from "@/services/fyApi";

type Props = {
  name: string;
  modelValue?: ValueType<ModelOption>;
  multiple?: boolean;
  noLabel?: boolean;
  size?: `${BaseSelectSizesEnum}`;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: false,
  noLabel: true,
  size: undefined,
});

const { t } = useI18n();

const internalValue = ref<ValueType<ModelOption> | undefined>(props.modelValue);

onMounted(() => {
  internalValue.value = props.modelValue;
});

watch(
  () => props.modelValue,
  () => {
    internalValue.value = props.modelValue;
  },
);

const emit = defineEmits(["update:modelValue"]);

watch(
  () => internalValue.value,
  () => {
    emit("update:modelValue", internalValue.value);
  },
);

const formatter = (response: ModelOptions) => {
  return response.items.map((model) => {
    return {
      label: model.name,
      value: model.slug,
      object: model,
    };
  });
};

const fetch = async (params: BaseSelectParams<ModelOption>) => {
  const q: ModelQuery = {};

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing) {
    if (props.multiple) {
      q.slugIn = params.missing as string[];
    } else {
      q.slugEq = params.missing as string;
    }
  }

  return fetchModelOptions({ page: String(params.page || 1), q });
};

const baseSelect = ref<ComponentExposed<typeof BaseSelect>>();

const clear = () => {
  internalValue.value = undefined;
  baseSelect.value?.clear();
};

const clearSearch = () => {
  baseSelect.value?.clearSearch();
};

const reset = () => {
  clear();
  clearSearch();
  baseSelect.value?.reset();
};

defineExpose({
  clear,
  clearSearch,
  reset,
});
</script>

<template>
  <BaseSelect
    ref="baseSelect"
    v-model="internalValue"
    :label="t('labels.selectModel')"
    :search-label="t('labels.findModel')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="true"
    :searchable="true"
    :multiple="multiple"
    :no-label="noLabel"
    :size="size"
  />
</template>
