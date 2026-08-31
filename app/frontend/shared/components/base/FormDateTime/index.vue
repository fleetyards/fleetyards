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
    <p
      :id="errorId"
      class="base-input__error"
      :class="{ 'base-input__error--shown': errorMessage }"
      role="alert"
    >
      <span>{{ errorMessage }}</span>
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
  display: flex;
  background-color: var(--color-field, rgb(18 20 23 / 0.96));
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

/*
 * `dp--`, not `dp__`. @vuepic/vue-datepicker 14 uses the first and has no class
 * of the second form anywhere -- so this component's entire stylesheet, palette
 * included, has never matched a single element. It rendered with the library's
 * stock dark theme throughout, which is why putting a proper frame on the
 * wrapper produced two nested boxes rather than one control.
 *
 * The palette that used to sit here is gone rather than corrected: the menu is
 * teleported to the body, so a scoped block cannot reach it in any case.
 * FormDatePicker carries a global `.dp--theme-dark` block for exactly that
 * reason, and that one does apply. Extracting it so it does not depend on which
 * component happens to be on the page is worth doing, and is not this change.
 */
.form-datetime__wrapper :deep(.dp--main),
.form-datetime__wrapper :deep(.dp--input-wrap) {
  flex: 1 1 auto;
  min-width: 0;
  width: 100%;
}

/*
 * The frame is the wrapper's; the input carries nothing.
 *
 * Deliberately identical to FormDatePicker's rule, declaration for declaration.
 * The two controls wrap the same library through two separate implementations,
 * and every line that exists in one and not the other shows up as the two
 * looking subtly unalike -- here it was the icon container keeping the library's
 * default padding, which pushed the calendar glyph over the first character of
 * the date.
 *
 * That they have to be kept identical by hand is the real defect. One of them
 * should wrap the other.
 */
.form-datetime__wrapper :deep(.dp--input) {
  display: block;
  box-sizing: border-box;
  width: 100%;
  height: calc(var(--field-h, 43px) - 2px);
  margin: 0;
  padding: 6px 12px 6px 36px;
  color: var(--color-text, #c8c8c8);
  font-family: inherit;
  font-size: 16px;
  font-weight: 400;
  line-height: 1.42857;
  text-overflow: ellipsis;
  background-color: transparent;
  background-image: none;
  border: none;
  border-radius: 0;
  box-shadow: none;
  transition: none;
  cursor: pointer;
}

/* Tighten the icon-container padding (default is 6px 12px) so the glyph sits
   inside the input's 36px left padding cleanly. */
.form-datetime__wrapper :deep(.dp--input-icons) {
  padding: 0;
}

.form-datetime__wrapper :deep(.dp--input)::placeholder {
  color: var(--color-endcap, #7a8288);
  opacity: 1;
}

.form-datetime__wrapper :deep(.dp--input):focus {
  outline: none;
}

.form-datetime__wrapper :deep(.dp--input-icon),
.form-datetime__wrapper :deep(.dp--clear-btn) {
  color: var(--color-endcap, #7a8288);
  fill: var(--color-endcap, #7a8288);
}

.form-datetime__wrapper :deep(.dp--input-icon) {
  inset-inline-start: 14px;
}

.form-datetime__wrapper :deep(.dp--clear-btn) {
  inset-inline-end: 14px;
}

/* Shared with every other control -- see the note in FormInput. */
.base-input__error {
  display: grid;
  grid-template-rows: 0fr;
  margin: 0;
  font-size: 0.875rem;
  line-height: var(--field-message-line, 1.25rem);
  color: var(--color-danger, #dc3545);
  opacity: 0;
  transition:
    grid-template-rows 180ms ease-in-out,
    margin-top 180ms ease-in-out,
    opacity 180ms ease-in-out;

  > span {
    overflow: hidden;
  }

  &--shown {
    grid-template-rows: 1fr;
    margin-top: var(--field-message-gap, 4px);
    opacity: 1;
  }

  @media (prefers-reduced-motion: reduce) {
    transition: none;
  }
}
</style>
