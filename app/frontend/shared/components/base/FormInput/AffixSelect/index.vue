<script lang="ts">
export default {
  name: "FormInputAffixSelect",
};
</script>

<script lang="ts" setup>
import { type FilterOption } from "@/services/fyApi";

type Props = {
  options: FilterOption[];
  label: string;
  modelValue?: string | number | null;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  disabled: false,
});

const emit = defineEmits(["update:modelValue"]);

const onChange = (event: Event) => {
  emit("update:modelValue", (event.target as HTMLSelectElement).value);
};
</script>

<template>
  <select
    class="form-input-affix-select"
    :value="props.modelValue"
    :disabled="props.disabled"
    :aria-label="props.label"
    @change="onChange"
  >
    <option
      v-for="option in props.options"
      :key="String(option.value)"
      :value="option.value"
    >
      {{ option.label }}
    </option>
  </select>
</template>

<style lang="scss" scoped>
@import "index";
</style>
