<script lang="ts">
export default {
  name: "ModelVehicleSizeSelect",
};
</script>

<script lang="ts" setup>
import { modelVehicleSizesFilters as fetchModelVehicleSizeFilters } from "@/services/fyApi";
import { type FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";

type Props = {
  name: string;
  modelValue?: string | string[] | null;
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  multiple: true,
  noLabel: true,
});

const { t } = useI18n();

const internalValue = ref<string | string[] | null | undefined>(
  props.modelValue,
);

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

const fetch = async (_params: BaseSelectParams<FilterOption>) => {
  return fetchModelVehicleSizeFilters();
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.filters.models.vehicleSize')"
    :query-fn="fetch"
    :name="name"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
