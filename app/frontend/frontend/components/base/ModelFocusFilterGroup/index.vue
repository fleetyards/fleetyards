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

<script lang="ts" setup>
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useI18n } from "@/frontend/composables/useI18n";
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

const { models: modelsService } = useApiClient();

const fetch = async (params: FilterGroupParams) => {
  const response = await modelsService.modelFocus();

  if (params.search && props.searchable) {
    return response.filter((item) => {
      return (
        item.label
          ?.toLowerCase()
          .includes(params.search?.toLowerCase() || "") ||
        item.value?.toLowerCase().includes(params.search?.toLowerCase() || "")
      );
    });
  }

  return response;
};
</script>

<script lang="ts">
export default {
  name: "ModelFocusFilterGroup",
};
</script>
