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

const internalId = ref(props.id ?? `${props.name}-${uuidv4()}`);

const errorId = computed(() => `${internalId.value}-error`);

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
    <!-- See the note in FormInput: below the control, and always present. -->
    <p :id="errorId" class="base-input__error" role="alert">
      {{ errorMessage }}
    </p>
  </div>
</template>

<style lang="scss">
// Calendar popup palette — vue-datepicker teleports the menu to body
// so this block intentionally lives outside any scoped wrapper.
.dp--theme-dark {
  --dp-font-family: inherit;
  /*
   * The popup is a surface, so it takes the opaque one BtnDropdown/Menu uses
   * rather than the control fill: it floats over arbitrary content, and a
   * translucent menu lets whatever it covers compete with its own labels.
   */
  --dp-background-color: var(--color-gray-darker, #272b30);
  --dp-text-color: var(--color-text, #c8c8c8);
  --dp-hover-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
  --dp-hover-text-color: var(--color-lifted, #eee);
  --dp-primary-color: var(--color-primary, #428bca);
  --dp-primary-text-color: #fff;
  --dp-secondary-color: var(--color-endcap, #7a8288);
  --dp-border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  --dp-menu-border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  --dp-border-color-hover: var(--color-endcap, #7a8288);
  --dp-border-color-focus: var(--color-primary, #428bca);
  --dp-icon-color: var(--color-endcap, #7a8288);
  --dp-disabled-color: var(--color-control, rgb(39 43 48 / 0.9));
  --dp-disabled-color-text: var(--color-endcap, #7a8288);
  --dp-border-radius: var(--radius-control, 8px);
  --dp-font-size: 16px;
  --dp-success-color: #{$success};
  --dp-danger-color: var(--color-danger, #dc3545);
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

  label {
    display: block;
    margin-bottom: var(--field-label-gap, 5px);
    line-height: var(--field-label-line, 1.5rem);
    white-space: nowrap;
  }

  /*
   * The control is the wrapper, not the input -- the same arrangement FormInput
   * uses, and for the same reason: an input renders no pseudo-elements, so it
   * cannot carry an end-cap.
   *
   * This component used to duplicate FormInput's *old* internals -- the comment
   * below still said "match FormInput exactly" while matching a version that no
   * longer existed -- which is how it ended up as the one un-migrated control in
   * a row of migrated ones.
   */
  .base-input__wrapper {
    position: relative;
    display: flex;
    background-color: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
    border-radius: var(--radius-control, 8px);
    transition: background-color ease-in-out 0.15s;

    &:hover {
      background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
    }

    &::before,
    &::after {
      position: absolute;
      right: max(10px, var(--cap-inset, 12%));
      left: max(10px, var(--cap-inset, 12%));
      height: var(--cap-h-btn, 2px);
      background-color: var(--field-cap, var(--color-endcap, #7a8288));
      border-radius: var(--cap-r-btn, 1px);
      transition: background-color 0.15s ease;
      content: "";
      z-index: 1;
    }

    &::before {
      top: -1px;
    }

    &::after {
      bottom: -1px;
    }
  }

  &:focus-within {
    --field-cap: var(--color-primary, #428bca);
  }

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
    background-color: transparent;
    background-image: none;
    border: none;
    border-radius: 0;
    transition: none;
    cursor: pointer;

    &::placeholder {
      color: var(--color-endcap, #7a8288);
      opacity: 1;
    }

    // The cap on the wrapper is the focus signal.
    &:focus {
      outline: none;
    }
  }

  // Calendar icon on the left + clear button on the right inherit the
  // FormInput muted-gray tone.
  :deep(.dp--input-icon),
  :deep(.dp--clear-btn) {
    color: var(--color-endcap, #7a8288);
    fill: var(--color-endcap, #7a8288);
  }

  :deep(.dp--input-icon) {
    inset-inline-start: 14px;
  }

  :deep(.dp--clear-btn) {
    inset-inline-end: 14px;
  }

  // The frame stays neutral; the signature says what is wrong.
  &.base-input--with-error {
    --field-cap: var(--color-danger, #dc3545);
  }

  &.base-input--disabled {
    --field-cap: transparent;

    .base-input__wrapper {
      border-color: var(--color-edge-faint, rgb(122 130 136 / 0.16));
      opacity: 0.5;

      &:hover {
        background-color: var(--color-control, rgb(39 43 48 / 0.9));
      }
    }

    :deep(.dp--input) {
      cursor: not-allowed;
    }
  }

  /*
   * The message, below the control -- see the note in FormInput. It borrowed
   * .base-input__error for its own element long before FormInput had one, which
   * is the name overlap noted there; both mean the same thing now.
   */
  .base-input__error {
    min-height: var(--field-message-line, 1.25rem);
    margin: var(--field-message-gap, 4px) 0 0;
    font-size: 0.875rem;
    line-height: var(--field-message-line, 1.25rem);
    color: var(--color-danger, #dc3545);
  }
}
</style>
