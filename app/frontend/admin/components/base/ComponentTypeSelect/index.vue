<script lang="ts">
export default {
  name: "ComponentTypeSelect",
};
</script>

<script lang="ts" setup>
import { ComponentTypeEnum, type FilterOption } from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect from "@/shared/components/base/Select/index.vue";

type Props = {
  name: string;
  modelValue?: ComponentTypeEnum;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
});

const emit = defineEmits(["update:modelValue"]);

const { t } = useI18n();

const options: FilterOption[] = Object.values(ComponentTypeEnum).map(
  (value) => ({ label: value, value }),
);

const internalValue = computed({
  get: () => props.modelValue,
  set: (value) => emit("update:modelValue", value),
});
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.component.componentType')"
    :options="options"
    :name="name"
    :multiple="false"
    :nullable="false"
    searchable
  />
</template>
