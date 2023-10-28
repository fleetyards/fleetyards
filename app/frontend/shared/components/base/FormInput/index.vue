<template>
  <div :key="id" class="form-input" :class="cssClasses">
    <transition name="fade">
      <label
        v-show="!hideLabelOnEmpty || inputValue"
        v-if="innerLabel && !noLabel"
        :for="id"
      >
        <i v-if="icon" :class="icon" />
        {{ innerLabel }}
      </label>
    </transition>
    <div
      class="form-input-wrapper"
      :class="{
        'from-input-wrapper-with-prefix': !!prefix,
        'from-input-wrapper-with-suffix': !!suffix,
      }"
    >
      <slot name="prefix">
        <div v-if="prefix" class="form-input-prefix">
          {{ prefix }}
        </div>
      </slot>
      <input
        :id="id"
        ref="inputElement"
        v-tooltip.right="hasErrors && errorMessage"
        :value="inputValue"
        :placeholder="innerPlaceholder"
        :type="type"
        :data-test="`input-${name}`"
        :aria-label="innerLabel"
        :autofocus="autofocus"
        :autocomplete="autocomplete"
        :disabled="disabled"
        :name="name"
        :min="min"
        :max="max"
        :step="innerStep"
        :class="{
          clearable,
        }"
        @input="onChange"
        @blur="handleBlur"
      />
      <slot name="suffix">
        <div v-if="suffix" class="form-input-suffix">
          {{ suffix }}
        </div>
      </slot>
      <div v-if="inputValue && clearable" class="clear">
        <i
          class="fal fa-times"
          :class="{
            'with-label': !!innerLabel && !noLabel,
          }"
          @click="clear"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useField } from "vee-validate";
import { v4 as uuidv4 } from "uuid";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

type Props = {
  name: string;
  icon?: string;
  modelValue?: string | number;
  type?: "text" | "number" | "password" | "email" | "url" | "color";
  translationKey?: string;
  autofocus?: boolean;
  autocomplete?: string;
  hideLabelOnEmpty?: boolean;
  label?: string;
  min?: number;
  max?: number;
  step?: number;
  noLabel?: boolean;
  noPlaceholder?: boolean;
  placeholder?: string;
  clearable?: boolean;
  disabled?: boolean;
  inline?: boolean;
  prefix?: string;
  suffix?: string;
  variant?: "default" | "clean";
  size?: "default" | "large";
};

const props = withDefaults(defineProps<Props>(), {
  icon: undefined,
  modelValue: undefined,
  type: "text",
  translationKey: undefined,
  autofocus: false,
  autocomplete: undefined,
  hideLabelOnEmpty: false,
  label: undefined,
  min: undefined,
  max: undefined,
  step: 0.01,
  noLabel: false,
  noPlaceholder: false,
  placeholder: undefined,
  clearable: false,
  disabled: false,
  inline: false,
  prefix: undefined,
  suffix: undefined,
  variant: "default",
  size: "default",
});

watch(
  () => props.modelValue,
  () => {
    resetField({
      value: props.modelValue,
    });
  },
);

const i18n = inject<I18nPluginOptions>("i18n");

const inputElement = ref<HTMLInputElement | undefined>();

const id = ref(`${props.name}-${uuidv4()}`);

const innerStep = computed(() => {
  if (props.type === "number") {
    return props.step;
  }

  return undefined;
});

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return i18n?.t(`labels.${props.translationKey}`);
  }

  return i18n?.t(`labels.${props.name}`);
});

const {
  value: inputValue,
  errorMessage,
  errors,
  handleChange,
  handleBlur,
  handleReset,
  resetField,
} = useField(props.name, undefined, {
  initialValue: props.modelValue,
  label: innerLabel.value,
});

const hasErrors = computed(() => {
  return errors.value.length;
});

const innerPlaceholder = computed(() => {
  if (props.noPlaceholder) {
    return undefined;
  }

  if (props.placeholder) {
    return props.placeholder;
  }

  if (props.translationKey) {
    return i18n?.t(`placeholders.${props.translationKey}`);
  }

  return i18n?.t(`placeholders.${props.name}`);
});

const cssClasses = computed(() => {
  return {
    "has-error has-feedback": hasErrors.value,
    "form-input-large": props.size === "large",
    "form-input-clean": props.variant === "clean",
    "form-input-clearable": props.clearable,
    "form-input-disabled": props.disabled,
    "form-input-inline": props.inline,
    [`form-input-${props.type}`]: true,
  };
});

onMounted(() => {
  id.value = `${props.name}-${uuidv4()}`;

  if (props.autofocus) {
    inputElement.value?.focus();
  }
});

const emit = defineEmits(["update:modelValue"]);

const clear = () => {
  handleReset();
  emit("update:modelValue", undefined);
};

const onChange = (event: Event) => {
  handleChange(event);
  emit("update:modelValue", inputValue.value);
};

const setFocus = () => {
  inputElement.value?.focus();
};

defineExpose({
  clear,
  setFocus,
});
</script>

<script lang="ts">
export default {
  name: "FormInput",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
