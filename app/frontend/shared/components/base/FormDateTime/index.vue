<script lang="ts">
export default {
  name: "FormDateTime",
};
</script>

<script lang="ts" setup>
import { VueDatePicker } from "@vuepic/vue-datepicker";
import "@vuepic/vue-datepicker/dist/main.css";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";

type DateFormatBuilder = {
  separator: string;
  parts: ("d" | "m" | "y")[];
};

const DATE_FORMAT_BUILDERS: Record<string, DateFormatBuilder> = {
  dmy_dots: { separator: ".", parts: ["d", "m", "y"] },
  dmy_slash: { separator: "/", parts: ["d", "m", "y"] },
  mdy_slash: { separator: "/", parts: ["m", "d", "y"] },
  ymd_dash: { separator: "-", parts: ["y", "m", "d"] },
};

type Props = {
  name: string;
  modelValue?: string | null;
  label?: string;
  translationKey?: string;
  noLabel?: boolean;
  errorMessage?: string;
  disabled?: boolean;
  clearable?: boolean;
  minutesIncrement?: number;
  enableTimePicker?: boolean;
  noPlaceholder?: boolean;
  placeholder?: string;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: undefined,
  label: undefined,
  translationKey: undefined,
  noLabel: false,
  errorMessage: undefined,
  disabled: false,
  clearable: true,
  minutesIncrement: 15,
  enableTimePicker: true,
  noPlaceholder: false,
  placeholder: undefined,
});

const emit = defineEmits<{
  "update:modelValue": [value: string | null];
}>();

const { t, tExists } = useI18n();

const internalId = `${props.name}-${uuidv4()}`;

const errorId = `${internalId}-error`;

const innerLabel = computed(() => {
  if (props.label) return props.label;
  if (props.translationKey) return t(`labels.${props.translationKey}`);
  return t(`labels.${props.name}`);
});

const innerPlaceholder = computed(() => {
  if (props.noPlaceholder) return undefined;
  if (props.placeholder) return props.placeholder;
  const key = `placeholders.${props.name}`;
  return tExists(key) ? t(key) : undefined;
});

const dateValue = computed<Date | null>(() => {
  if (!props.modelValue) return null;
  const parsed = new Date(props.modelValue);
  return isNaN(parsed.getTime()) ? null : parsed;
});

const onUpdate = (next: Date | null) => {
  if (!next) {
    emit("update:modelValue", null);
    return;
  }
  const pad = (n: number) => n.toString().padStart(2, "0");
  const formatted = `${next.getFullYear()}-${pad(next.getMonth() + 1)}-${pad(
    next.getDate(),
  )}T${pad(next.getHours())}:${pad(next.getMinutes())}`;
  emit("update:modelValue", formatted);
};

const hasErrors = computed(() => !!props.errorMessage);

const sessionStore = useSessionStore();

const userDateFormatBuilder = computed<DateFormatBuilder>(() => {
  const key = sessionStore.currentUser?.dateFormat ?? "dmy_dots";
  return DATE_FORMAT_BUILDERS[key] ?? DATE_FORMAT_BUILDERS.dmy_dots;
});

const formatFn = (date: Date | Date[] | null) => {
  if (!date) return "";
  const d = Array.isArray(date) ? date[0] : date;
  if (!d) return "";
  const pad = (n: number) => n.toString().padStart(2, "0");
  const builder = userDateFormatBuilder.value;
  const tokens: Record<"d" | "m" | "y", string> = {
    d: pad(d.getDate()),
    m: pad(d.getMonth() + 1),
    y: d.getFullYear().toString(),
  };
  const datePart = builder.parts
    .map((part) => tokens[part])
    .join(builder.separator);
  if (!props.enableTimePicker) return datePart;
  return `${datePart} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

const formatsConfig = computed(() => ({
  input: formatFn,
  preview: formatFn,
}));

const timeConfig = computed(() => ({
  timePickerInline: props.enableTimePicker,
}));
</script>

<template>
  <div
    class="base-input form-datetime"
    :class="{ 'base-input--with-error': hasErrors }"
    :data-test="`datetime-wrapper-${name}`"
  >
    <label v-if="innerLabel && !noLabel" :for="internalId">
      {{ innerLabel }}
    </label>
    <div class="form-datetime__wrapper">
      <VueDatePicker
        :uid="internalId"
        :model-value="dateValue"
        :clearable="clearable"
        :enable-time-picker="enableTimePicker"
        :minutes-increment="minutesIncrement"
        :is-24="true"
        :auto-apply="true"
        :placeholder="innerPlaceholder"
        :disabled="disabled"
        :formats="formatsConfig"
        :time-config="timeConfig"
        dark
        @update:model-value="onUpdate"
      />
    </div>
    <p :id="errorId" class="base-input__error" role="alert">
      {{ errorMessage }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
/*
 * This was a third dialect: the same picker library as FormDatePicker but a
 * separate implementation, with its own wrapper, its own small uppercase label,
 * and a palette written against `--input-bg` and `--danger` -- neither of which
 * exists, so both always fell through to their literals. `#c62828` is not the
 * red the rest of the forms use, so a page with two invalid controls showed two
 * different reds.
 */
.form-datetime {
  margin-bottom: 1rem;
}

.form-datetime label {
  display: block;
  margin-bottom: var(--field-label-gap, 5px);
  line-height: var(--field-label-line, 1.5rem);
  white-space: nowrap;
}

/* The control is the wrapper; see the note in FormInput. */
.form-datetime__wrapper {
  position: relative;
  background-color: var(--color-control, rgb(39 43 48 / 0.9));
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-control, 8px);
  transition: background-color ease-in-out 0.15s;
}

.form-datetime__wrapper:hover {
  background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
}

.form-datetime__wrapper::before,
.form-datetime__wrapper::after {
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

.form-datetime__wrapper::before {
  top: -1px;
}

.form-datetime__wrapper::after {
  bottom: -1px;
}

.form-datetime:focus-within {
  --field-cap: var(--color-primary, #428bca);
}

.form-datetime.base-input--with-error {
  --field-cap: var(--color-danger, #dc3545);
}

.form-datetime__wrapper :deep(.dp__main) {
  --dp-input-icon-padding: 2.6rem;
  --dp-input-padding: 0.55rem 2.4rem 0.55rem 0.75rem;
  --dp-background-color: transparent;
  --dp-text-color: var(--color-text, #c8c8c8);
  --dp-hover-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
  --dp-hover-text-color: var(--color-lifted, #eee);
  --dp-hover-icon-color: var(--color-primary, #428bca);
  --dp-primary-color: var(--color-primary, #428bca);
  --dp-primary-text-color: #fff;
  --dp-secondary-color: var(--color-endcap, #7a8288);
  --dp-border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  --dp-border-color-hover: var(--color-endcap, #7a8288);
  --dp-border-color-focus: var(--color-primary, #428bca);
  --dp-menu-border-color: var(--color-edge, rgb(122 130 136 / 0.5));
  --dp-disabled-color: var(--color-control, rgb(39 43 48 / 0.9));
  --dp-scroll-bar-background: rgb(255 255 255 / 0.05);
  --dp-scroll-bar-color: rgb(255 255 255 / 0.2);
  --dp-success-color: var(--color-success, #5cb85c);
  --dp-success-color-disabled: rgb(76 175 80 / 0.4);
  --dp-icon-color: var(--color-endcap, #7a8288);
  --dp-danger-color: var(--color-danger, #dc3545);
  --dp-highlight-color: rgb(66 139 202 / 0.35);
  --dp-menu-min-width: 260px;
  --dp-border-radius: var(--radius-control, 8px);
}

/* The frame is the wrapper's now. */
.form-datetime__wrapper :deep(.dp__input) {
  height: var(--field-h, 43px);
  font-family: inherit;
  font-size: 16px;
  background-color: transparent;
  border: none;
  border-radius: 0;
}

/* Shared with every other control -- see the note in FormInput. */
.base-input__error {
  min-height: var(--field-message-line, 1.25rem);
  margin: 4px 0 0;
  font-size: 0.875rem;
  line-height: var(--field-message-line, 1.25rem);
  color: var(--color-danger, #dc3545);
}
</style>
