<script lang="ts">
export default {
  name: "FormDatePicker",
};
</script>

<script lang="ts" setup>
import { useField, type RuleExpression } from "vee-validate";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";
import { toLocalIsoDate } from "@/shared/utils/dateHelpers";
import { VueDatePicker } from "@vuepic/vue-datepicker";
import "@vuepic/vue-datepicker/dist/main.css";
import type { MaybeRef } from "vue";

const DATE_ONLY_RE = /^\d{4}-\d{2}-\d{2}$/;

// `new Date('YYYY-MM-DD')` parses as UTC midnight; for users west of UTC
// the resulting Date falls on the previous local day. Parse as local
// midnight instead when the value is a date-only string.
const parseLocal = (value: string): Date => {
  if (DATE_ONLY_RE.test(value)) {
    const [year, month, day] = value.split("-").map(Number);
    return new Date(year, month - 1, day);
  }
  return new Date(value);
};

type Props = {
  id?: string;
  name: string;
  rules?: MaybeRef<RuleExpression<string | null>>;
  icon?: string;
  modelValue?: string | null;
  translationKey?: string;
  label?: string;
  noLabel?: boolean;
  placeholder?: string;
  noPlaceholder?: boolean;
  clearable?: boolean;
  disabled?: boolean;
  withTime?: boolean;
  minDate?: string | Date;
  maxDate?: string | Date;
};

const props = withDefaults(defineProps<Props>(), {
  id: undefined,
  rules: undefined,
  icon: undefined,
  modelValue: undefined,
  translationKey: undefined,
  label: undefined,
  noLabel: false,
  placeholder: undefined,
  noPlaceholder: false,
  clearable: true,
  disabled: false,
  withTime: false,
  minDate: undefined,
  maxDate: undefined,
});

const emit = defineEmits<{
  "update:modelValue": [value: string | null | undefined];
  clear: [];
}>();

const { t } = useI18n();

const internalId = ref(`${props.name}-${uuidv4()}`);

const innerLabel = computed(() => {
  if (props.label) return props.label;
  if (props.translationKey) return t(`labels.${props.translationKey}`);
  return t(`labels.${props.name}`);
});

const innerPlaceholder = computed(() => {
  if (props.noPlaceholder) return undefined;
  if (props.placeholder) return props.placeholder;
  if (props.translationKey) return t(`placeholders.${props.translationKey}`);
  return t(`placeholders.${props.name}`);
});

const {
  value: fieldValue,
  errorMessage,
  errors,
  handleChange,
  handleReset,
  resetField,
} = useField<string | null>(props.name, props.rules, {
  initialValue: props.modelValue ?? null,
  label: innerLabel.value,
});

const hasErrors = computed(() => errors.value.length > 0);

const pickerValue = computed<Date | null>({
  get: () => (fieldValue.value ? parseLocal(fieldValue.value) : null),
  set: (next) => {
    const serialized = next
      ? props.withTime
        ? next.toISOString()
        : toLocalIsoDate(next)
      : null;
    handleChange(serialized);
    emit("update:modelValue", serialized);
  },
});

const inputFormat = computed(() =>
  props.withTime ? "d MMM yyyy HH:mm" : "d MMM yyyy",
);

const timeConfig = computed(() => ({
  enableTimePicker: props.withTime,
  timePickerInline: props.withTime,
}));

watch(
  () => props.modelValue,
  (next) => {
    resetField({
      value: next ?? null,
    });
  },
);

const clear = () => {
  handleReset();
  emit("update:modelValue", undefined);
  emit("clear");
};

onMounted(() => {
  if (props.id) {
    internalId.value = props.id;
  } else {
    internalId.value = `${props.name}-${uuidv4()}`;
  }
});

defineExpose({ clear });
</script>

<template>
  <div
    :key="internalId"
    class="base-input form-date-picker"
    :class="{
      'base-input--with-error': hasErrors,
      'base-input--disabled': disabled,
    }"
    :data-test="`input-wrapper-${name}`"
  >
    <label v-if="innerLabel && !noLabel" :for="internalId">
      <i v-if="icon" :class="icon" />
      {{ innerLabel }}
    </label>
    <div class="base-input__wrapper">
      <VueDatePicker
        v-model="pickerValue"
        v-tooltip.right="hasErrors && errorMessage"
        :uid="internalId"
        :name="name"
        :placeholder="innerPlaceholder"
        :clearable="clearable"
        :disabled="disabled"
        :time-config="timeConfig"
        :formats="{ input: inputFormat, preview: inputFormat }"
        auto-apply
        :min-date="minDate"
        :max-date="maxDate"
        dark
        :data-test="`input-${name}`"
        @cleared="clear"
      />
    </div>
  </div>
</template>

<style lang="scss">
// Calendar popup palette — vue-datepicker teleports the menu to body
// so this block intentionally lives outside any scoped wrapper.
.dp--theme-dark {
  --dp-font-family: inherit;
  --dp-background-color: #{$input-bg};
  --dp-text-color: #{$input-color};
  --dp-hover-color: #{color.adjust($input-bg, $lightness: 5%)};
  --dp-hover-text-color: #{$input-color};
  --dp-primary-color: #{$primary};
  --dp-primary-text-color: #fff;
  --dp-secondary-color: #{$gray-light};
  --dp-border-color: #{$input-border};
  --dp-menu-border-color: #{$input-border};
  --dp-border-color-hover: #{color.adjust($input-border, $lightness: 8%)};
  --dp-border-color-focus: #{$primary};
  --dp-icon-color: #{$gray-light};
  --dp-disabled-color: #{$input-bg};
  --dp-disabled-color-text: #{color.adjust($input-color, $lightness: -10%)};
  --dp-border-radius: 3px;
  --dp-font-size: 16px;
  --dp-success-color: #{$success};
  --dp-danger-color: #{$danger};
}
</style>

<style lang="scss" scoped>
.form-date-picker {
  margin-bottom: 1rem;

  :deep(.dp--main),
  :deep(.dp--input-wrap) {
    width: 100%;
  }

  // Tighten the icon-container padding (default is 6px 12px) so the visible
  // calendar glyph sits inside the input's 36px left padding cleanly.
  :deep(.dp--input-icons) {
    padding: 0;
  }

  // Match `.base-input__wrapper input` from FormInput exactly.
  :deep(.dp--input) {
    display: block;
    box-sizing: border-box;
    width: 100%;
    height: 43px;
    padding: 6px 12px 6px 36px; // 36px left padding leaves room for the calendar icon
    margin: 0;
    color: $input-color;
    font-size: 16px;
    font-weight: 400;
    line-height: 1.42857;
    font-family: inherit;
    text-overflow: ellipsis;
    background-color: $input-bg;
    background-image: none;
    border: 1px solid $input-border;
    border-radius: 3px;
    box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
    transition: none;
    cursor: pointer;

    &::placeholder {
      color: $input-placerholder;
      opacity: 1;
    }

    &:focus {
      outline: none;
      border-color: $input-border;
      box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
    }
  }

  // Calendar icon on the left + clear button on the right inherit the
  // FormInput muted-gray tone.
  :deep(.dp--input-icon),
  :deep(.dp--clear-btn) {
    color: $gray-light;
    fill: $gray-light;
  }

  :deep(.dp--input-icon) {
    inset-inline-start: 14px;
  }

  :deep(.dp--clear-btn) {
    inset-inline-end: 14px;
  }

  &.base-input--with-error :deep(.dp--input) {
    border-color: color.adjust($danger, $lightness: -15%);
  }

  &.base-input--disabled :deep(.dp--input) {
    color: color.adjust($input-color, $lightness: -10%);
    cursor: not-allowed;
    opacity: 0.9;
  }
}
</style>
