<script lang="ts">
export default {
  name: "ModelFilterGroup",
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
import FilterGroup, {
  type FilterGroupParams,
  type ValueType,
} from "@/shared/components/base/FilterGroup/index.vue";
import { modelOptions as fetchModelOptions } from "@/services/fyApi";

type Props = {
  name: string;
  modelValue?: ValueType<ModelOption>;
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: false,
  noLabel: true,
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

const fetch = async (params: FilterGroupParams<ModelOption>) => {
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

const filterGroup = ref<ComponentExposed<typeof FilterGroup>>();

const clear = () => {
  internalValue.value = undefined;
  filterGroup.value?.clear();
};

const clearSearch = () => {
  filterGroup.value?.clearSearch();
};

const reset = () => {
  clear();
  clearSearch();
  filterGroup.value?.reset();
};

defineExpose({
  clear,
  clearSearch,
  reset,
});
</script>

<template>
  <FilterGroup
    ref="filterGroup"
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
  />
</template>
