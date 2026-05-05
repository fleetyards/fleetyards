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
    <div v-if="hasErrors" class="base-input__error" role="alert">
      {{ errorMessage }}
    </div>
  </div>
</template>

<style lang="scss" scoped>
.form-datetime {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-bottom: 1rem;
}
.form-datetime label {
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--text-muted);
}
.form-datetime__wrapper :deep(.dp__main) {
  --dp-input-icon-padding: 2.6rem;
  --dp-input-padding: 0.55rem 2.4rem 0.55rem 0.75rem;
  --dp-background-color: var(--input-bg, rgba(0, 0, 0, 0.4));
  --dp-text-color: var(--text);
  --dp-hover-color: rgba(74, 170, 170, 0.2);
  --dp-hover-text-color: var(--text);
  --dp-hover-icon-color: var(--accent, #4aa);
  --dp-primary-color: var(--accent, #4aa);
  --dp-primary-text-color: #fff;
  --dp-secondary-color: var(--text-muted);
  --dp-border-color: rgba(255, 255, 255, 0.15);
  --dp-border-color-hover: rgba(255, 255, 255, 0.3);
  --dp-disabled-color: rgba(255, 255, 255, 0.1);
  --dp-scroll-bar-background: rgba(255, 255, 255, 0.05);
  --dp-scroll-bar-color: rgba(255, 255, 255, 0.2);
  --dp-success-color: var(--success, #4caf50);
  --dp-success-color-disabled: rgba(76, 175, 80, 0.4);
  --dp-icon-color: var(--text-muted);
  --dp-danger-color: var(--danger, #c62828);
  --dp-highlight-color: rgba(74, 170, 170, 0.5);
  --dp-menu-min-width: 260px;
}
.form-datetime__wrapper :deep(.dp__input) {
  font-family: inherit;
  font-size: 0.95rem;
  border-radius: 4px;
}
.base-input__error {
  color: var(--danger, #c62828);
  font-size: 0.78rem;
}
</style>
