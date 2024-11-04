<script lang="ts">
export default {
  name: "FormCheckbox",
};
</script>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { useField } from "vee-validate";

type Props = {
  name: string;
  label?: string;
  modelValue?: boolean | string | (string | number)[] | null;
  disabled?: boolean;
  checkboxValue?: string | number;
  slim?: boolean;
  inline?: boolean;
  partial?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  modelValue: undefined,
  disabled: false,
  checkboxValue: undefined,
  slim: true,
  inline: false,
  partial: false,
});

const { value, errorMessage } = useField(props.name);

const internalValue = ref<boolean | (string | number)[]>();

const uuid = ref(`${props.name}-${uuidv4()}`);

const checked = computed(() => {
  return Array.isArray(internalValue.value) && props.checkboxValue
    ? internalValue.value.includes(props.checkboxValue)
    : internalValue.value;
});

watch(
  () => props.modelValue,
  () => {
    value.value = props.modelValue;
  },
);

onMounted(() => {
  uuid.value = `${props.name}-${uuidv4()}`;

  value.value = props.modelValue;
});

const emit = defineEmits(["update:modelValue"]);

const update = () => {
  emit("update:modelValue", value.value);
};
</script>

<template>
  <div
    class="base-checkbox"
    :class="{
      'base-checkbox--expanded': !slim,
      'base-checkbox--inline': inline,
      'base-checkbox--partial': partial,
    }"
  >
    <input
      :id="uuid"
      v-model="value"
      v-tooltip.right="errorMessage"
      :name="name"
      :checked="checked"
      :disabled="disabled"
      type="checkbox"
      :value="checkboxValue"
      :data-test="`checkbox-${name}`"
      @update:model-value="update"
    />
    <label :for="uuid">
      {{ label }}
    </label>
    {{ errorMessage }}
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
