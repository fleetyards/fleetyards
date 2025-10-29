<script lang="ts">
export default {
  name: "ProductionStatusFilterGroup",
};
</script>

<script lang="ts" setup>
import {
  modelProductionStates as fetchModelProductionStates,
  type FilterOption,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[];
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
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

const fetch = async (_params: FilterGroupParams<FilterOption>) => {
  return fetchModelProductionStates();
};
</script>

<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.models.productionStatus')"
    :query-fn="fetch"
    :name="name"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
