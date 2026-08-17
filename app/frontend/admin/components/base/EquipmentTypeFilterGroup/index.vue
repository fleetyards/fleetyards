<script lang="ts">
export default {
  name: "EquipmentTypeFilterGroup",
};
</script>

<script lang="ts" setup>
import {
  equipmentTypes as fetchEquipmentTypes,
  type FilterOption,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

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

const internalValue = ref<string | string[] | undefined>(
  props.modelValue ?? undefined,
);

onMounted(() => {
  internalValue.value = props.modelValue ?? undefined;
});

watch(
  () => props.modelValue,
  () => {
    internalValue.value = props.modelValue ?? undefined;
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
  return fetchEquipmentTypes();
};
</script>

<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.equipment.equipmentType')"
    :query-fn="fetch"
    :name="name"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
