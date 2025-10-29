<script lang="ts">
export default {
  name: "ModelFilterGroup",
};
</script>

<script lang="ts" setup>
import { ComponentExposed } from "vue-component-type-helpers";
import { models as fetchModels } from "@/services/fyApi";
import { type Models, type Model, type ModelQuery } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  multiple?: boolean;
  noLabel?: boolean;
  returnObject?: boolean;
  translationKey?: string;
  hideSelected?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  translationKey: undefined,
  multiple: false,
  noLabel: true,
  returnObject: false,
  hideSelected: false,
});

const { t } = useI18n();

const internalValue = ref<string | string[] | undefined>(props.modelValue);

const filterGroup = ref<ComponentExposed<typeof FilterGroup>>();

onMounted(() => {
  internalValue.value = props.modelValue;
});

watch(
  () => props.modelValue,
  () => {
    internalValue.value = props.modelValue;
  },
);

const emits = defineEmits(["update:modelValue"]);

watch(
  () => internalValue.value,
  () => {
    emits("update:modelValue", internalValue.value);
  },
);

const formatter = (response: Models) => {
  return response.items.map((model) => {
    return {
      label: model.name,
      value: model.slug,
    };
  });
};

const fetch = async (params: FilterGroupParams<Model>) => {
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

  return fetchModels({
    page: String(params.page || 1),
    q,
  });
};

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
    :label="translationKey ? undefined : t('labels.selectModel')"
    :search-label="translationKey ? undefined : t('labels.findModel')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :translation-key="translationKey"
    :name="name"
    :paginated="true"
    :searchable="true"
    :multiple="multiple"
    :no-label="noLabel"
    :return-object="returnObject"
    :hide-selected="hideSelected"
  />
</template>
