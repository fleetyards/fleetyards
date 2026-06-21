<script lang="ts">
export default {
  name: "FormInput",
};
</script>

<script lang="ts" setup>
import { type MaybeRef } from "vue";
import { useField, type RuleExpression } from "vee-validate";
import { v4 as uuidv4 } from "uuid";
import {
  InputTypesEnum,
  InputVariantsEnum,
  InputSizesEnum,
  InputAlignmentsEnum,
} from "@/shared/components/base/FormInput/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  id?: string;
  name: string;
  rules?: MaybeRef<RuleExpression<string | number | null>>;
  icon?: string;
  modelValue?: string | number | null;
  type?: `${InputTypesEnum}`;
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
  variant?: InputVariantsEnum;
  size?: InputSizesEnum;
  alignment?: InputAlignmentsEnum;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  icon: undefined,
  rules: undefined,
  modelValue: undefined,
  type: InputTypesEnum.TEXT,
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
  variant: InputVariantsEnum.DEFAULT,
  size: InputSizesEnum.DEFAULT,
  alignment: InputAlignmentsEnum.LEFT,
});

watch(
  () => props.modelValue,
  () => {
    resetField({
      value: props.modelValue,
    });
  },
);

const { t } = useI18n();

const inputElement = ref<HTMLInputElement | undefined>();

const internalId = ref(`${props.name}-${uuidv4()}`);

const innerStep = computed(() => {
  if (props.type === "number") {
    return props.step;
  }

  if (props.type === "date" || props.type === "datetime-local") {
    // Only forward an explicitly set step; the default `0.01` would be
    // nonsensical for date/datetime-local inputs.
    return props.step !== 0.01 ? props.step : undefined;
  }

  return undefined;
});

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return t(`labels.${props.translationKey}`);
  }

  return t(`labels.${props.name}`);
});

const {
  value: inputValue,
  errorMessage,
  errors,
  handleChange,
  handleBlur,
  handleReset,
  resetField,
} = useField(props.name, props.rules, {
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
    return t(`placeholders.${props.translationKey}`);
  }

  return t(`placeholders.${props.name}`);
});

const cssClasses = computed(() => {
  return {
    "base-input--with-error": hasErrors.value,
    "base-input--large": props.size === InputSizesEnum.LARGE,
    "base-input--clean": props.variant === InputVariantsEnum.CLEAN,
    "base-input--clearable": props.clearable,
    "base-input--disabled": props.disabled,
    "base-input--inline": props.inline,
    "base-input--align-left": props.alignment === InputAlignmentsEnum.LEFT,
    "base-input--align-right": props.alignment === InputAlignmentsEnum.RIGHT,
    [`base-input--${props.type}`]: true,
  };
});

onMounted(() => {
  if (props.id) {
    internalId.value = props.id;
  } else {
    internalId.value = `${props.name}-${uuidv4()}`;
  }

  if (props.autofocus) {
    inputElement.value?.focus();
  }
});

const emit = defineEmits(["update:modelValue", "clear"]);

const clear = () => {
  handleReset();
  emit("update:modelValue", undefined);
  emit("clear");
};

const onChange = (event: Event) => {
  handleChange(event);
  emit("update:modelValue", inputValue.value);
};

const setFocus = () => {
  inputElement.value?.focus();
};

const slots = useSlots();

defineExpose({
  clear,
  setFocus,
});
</script>

<template>
  <div
    :key="id"
    class="base-input"
    :class="cssClasses"
    :data-test="`input-wrapper-${name}`"
  >
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
      class="base-input__wrapper"
      :class="{
        'base-input__wrapper--with-prefix': !!prefix || !!slots.prefix,
        'base-input__wrapper--with-suffix': !!suffix || !!slots.suffix,
      }"
    >
      <slot name="prefix">
        <div v-if="prefix" class="base-input__prefix">
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
      <div v-if="suffix || slots.suffix" class="base-input__suffix">
        <slot name="suffix">
          {{ suffix }}
        </slot>
      </div>
      <div
        v-if="inputValue && clearable"
        class="base-input__clear"
        @click="clear"
      >
        <i
          class="fa-light fa-times"
          :class="{
            'with-label': !!innerLabel && !noLabel,
          }"
        />
      </div>
    </div>
    <div v-if="slots.subline" class="base-input__subline">
      <slot name="subline"></slot>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
