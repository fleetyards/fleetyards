<script lang="ts">
export default {
  name: "ModelFocusFilterGroup",
};
</script>

<script lang="ts" setup>
import {
  modelFocusFilters as fetchModelFocus,
  type Model,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  searchable?: boolean;
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  searchable: true,
  multiple: true,
  noLabel: true,
});

const { t } = useI18n();

const internalValue = ref<string | string[] | undefined>(props.modelValue);

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

const fetch = async (params: FilterGroupParams<Model>) => {
  const response = await fetchModelFocus();

  if (params.search && props.searchable) {
    return response.filter((item) => {
      const value = `${item.value}`.toLowerCase();
      return (
        item.label
          ?.toLowerCase()
          .includes(params.search?.toLowerCase() || "") ||
        value.includes(params.search?.toLowerCase() || "")
      );
    });
  }

  return response;
};
</script>

<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.models.focus')"
    :query-fn="fetch"
    :name="name"
    :searchable="searchable"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
