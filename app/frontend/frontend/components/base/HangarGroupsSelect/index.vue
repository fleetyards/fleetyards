<script lang="ts">
export default {
  name: "HangarGroupsSelect",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import {
  hangarGroups as fetchHangarGroups,
  type FilterOption,
  type HangarGroup,
} from "@/services/fyApi";

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

const fetch = (_params: BaseSelectParams<FilterOption>) => {
  return fetchHangarGroups();
};

const formatter = (groups: HangarGroup[]) => {
  return groups.map((group) => ({
    label: group.name,
    value: group.id,
  }));
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.filters.vehicles.group')"
    :query-fn="fetch"
    :query-response-formatter="formatter"
    :name="name"
    :paginated="false"
    :searchable="false"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
