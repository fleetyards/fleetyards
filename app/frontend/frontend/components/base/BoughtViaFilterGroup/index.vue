<script lang="ts">
export default {
  name: "BoughtViaFilterGroup",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useHangarQueries } from "@/frontend/composables/useHangarQueries";

const { boughtViaFilterQuery } = useHangarQueries();

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
</script>

<template>
  <FilterGroup
    v-model="internalValue"
    :label="t('labels.filters.vehicles.boughtVia')"
    :query-fn="boughtViaFilterQuery"
    :name="name"
    :paginated="false"
    :searchable="false"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
