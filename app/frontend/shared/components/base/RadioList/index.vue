<template>
  <div class="radio-list">
    <label :for="uuid" class="radio-list__label">
      {{ label }}
    </label>
    <div class="radio-list__wrapper">
      <div
        v-if="resetLabel"
        :class="{ 'radio-inline': inline }"
        class="radio-list__item"
      >
        <input
          :id="`${uuid}-reset`"
          :checked="!modelValue"
          :disabled="disabled"
          :name="name"
          type="radio"
          @change="clear"
        />
        <label :for="`${uuid}-reset`">
          {{ resetLabel }}
        </label>
      </div>
      <div
        v-for="(option, index) in options"
        :key="`${uuid}-${option.value}-${index}`"
        :class="{ 'radio-inline': inline }"
        class="radio-list__item"
      >
        <input
          :id="`${uuid}-${option.value}`"
          :checked="modelValue === option.value"
          :disabled="disabled"
          :name="name"
          :value="option.value"
          type="radio"
          @change="change"
        />
        <label :for="`${uuid}-${option.value}`" class="radio-list__label">
          {{ option.label }}
        </label>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";

type FormRadioListOption = {
  label: string;
  value: string;
};

type Props = {
  name: string;
  label: string;
  options: FormRadioListOption[];
  resetLabel?: string;
  modelValue?: string | number | boolean;
  inline?: boolean;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  resetLabel: undefined,
  modelValue: undefined,
  inline: true,
  disabled: false,
});

const uuid = ref(`${props.name}-${uuidv4()}`);

onMounted(() => {
  uuid.value = `${props.name}-${uuidv4()}`;
});

const emit = defineEmits(["update:modelValue"]);

const change = (event: Event) => {
  emit("update:modelValue", (event.target as HTMLInputElement).value);
};

const clear = () => {
  emit("update:modelValue", undefined);
};

defineExpose({
  clear,
});
</script>

<script lang="ts">
export default {
  name: "FormRadioList",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
