<template>
  <div
    class="form-group form-group-checkbox"
    :class="{
      'form-group-checkbox-expanded': !slim,
    }"
  >
    <input
      :id="uuid"
      v-model="internalValue"
      :name="name"
      :checked="checked"
      :disabled="disabled"
      class="form-checkbox"
      type="checkbox"
      :value="checkboxValue"
      :data-test="`checkbox-${name}`"
      @update:model-value="update"
    />
    <label :for="uuid">
      {{ label }}
    </label>
  </div>
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";

type Props = {
  name: string;
  label?: string;
  modelValue?: boolean | (string | number)[];
  disabled?: boolean;
  checkboxValue?: string | number;
  slim?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  modelValue: undefined,
  disabled: false,
  checkboxValue: undefined,
  slim: true,
});

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
    internalValue.value = props.modelValue;
  },
);

onMounted(() => {
  uuid.value = `${props.name}-${uuidv4()}`;

  internalValue.value = props.modelValue;
});

const emit = defineEmits(["update:modelValue"]);

const update = () => {
  emit("update:modelValue", internalValue.value);
};
</script>

<script lang="ts">
export default {
  name: "FormCheckbox",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
