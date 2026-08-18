<script lang="ts">
export default {
  name: "EquipmentSlotFilterGroup",
};
</script>

<script lang="ts" setup>
import {
  equipmentSlots as fetchEquipmentSlots,
  type FilterOption,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import FilterGroup, {
  type FilterGroupParams,
} from "@/shared/components/base/FilterGroup/index.vue";

type Props = {
  name: string;
  // Nullable, unlike the other filter groups: equipment that is not worn has no
  // slot, so the forms bind a value that can legitimately come back null.
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
  return fetchEquipmentSlots();
};
</script>

<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.equipment.slot')"
    :query-fn="fetch"
    :name="name"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
