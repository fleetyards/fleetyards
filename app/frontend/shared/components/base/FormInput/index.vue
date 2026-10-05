<script lang="ts">
export default {
  name: "FormInput",
};
</script>

<script lang="ts" setup>
import HintIcon from "@/shared/components/base/HintIcon/index.vue";
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
  // The keyboard a touch device offers. "decimal" is how a text field takes a
  // number it parses itself, where a native number field would not.
  inputmode?: "text" | "decimal" | "numeric" | "tel" | "email" | "url";
  hideLabelOnEmpty?: boolean;
  label?: string;
  min?: number;
  max?: number;
  step?: number;
  // Rendered beside the label, so it is absent when the label is.
  info?: string;
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
  // Kept out of the surrounding form's values and validation: a field that
  // serves a control inside a form (a link address in an editor) rather than
  // being one of the form's own fields.
  standalone?: boolean;
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
  inputmode: undefined,
  hideLabelOnEmpty: false,
  label: undefined,
  min: undefined,
  max: undefined,
  step: 0.01,
  info: undefined,
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
  standalone: false,
});

watch(
  () => props.modelValue,
  () => {
    /*
     * Carrying `touched` across, because this is a value being synced and not a
     * field being started over. resetField clears the whole state, and dropping
     * "has been visited" here silently switched the error message back off after
     * every keystroke -- every keystroke emits update:modelValue, the parent
     * writes it back, and this runs.
     */
    resetField({
      value: props.modelValue,
      touched: meta.touched,
    });
  },
);

const { t, tExists } = useI18n();

const inputElement = ref<HTMLInputElement | undefined>();

const internalId = ref(props.id || `${props.name}-${uuidv4()}`);

/*
 * internalId was written to give the input an id when a call site does not pass
 * one, and the template used the raw `id` prop instead -- which no call site
 * passes at all. So every input in the app had no id and every label no `for`:
 * clicking a label did nothing, and nothing tied the two together for assistive
 * tech.
 */
const errorId = computed(() => `${internalId.value}-error`);

const innerStep = computed(() => {
  if (props.type === "number") {
    return props.step;
  }

  if (
    props.type === "date" ||
    props.type === "datetime-local" ||
    props.type === "time"
  ) {
    // Only forward an explicitly set step; the default `0.01` would be
    // nonsensical for date and time inputs.
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
  meta,
  handleChange,
  handleBlur,
  handleReset,
  resetField,
} = useField(props.name, props.rules, {
  initialValue: props.modelValue,
  label: innerLabel.value,
  controlled: !props.standalone,
});

/*
 * An error is worth showing once the field has been left, not while it is being
 * typed into. vee-validate validates on every keystroke either way; before the
 * redesign that was invisible, because the message lived in a hover tooltip, and
 * moving it inline turned it into a field correcting someone mid-word -- "must
 * be at least 8 characters" on the first letter of a password.
 *
 * `touched` is set by handleBlur and by submitting, which are exactly the two
 * moments the message is useful. After the first blur it stays true, so a
 * message a reader is now fixing updates as they type rather than waiting for
 * another blur.
 *
 * The blur handler is passed `shouldValidate` for the same reason: on its own
 * handleBlur only marks the field, and vee-validate otherwise validates on a
 * value change. Tabbing through an empty required field changes nothing, so
 * without this there was no error to gate and the field stayed silent until the
 * form was submitted.
 *
 * This gate is for controls that are typed into. A checkbox, a toggle, a date
 * picker and a file input change by one deliberate act, so there is no
 * mid-word to interrupt and they report as soon as they are wrong.
 */
const hasErrors = computed(() => {
  return errors.value.length > 0 && meta.touched;
});

const innerPlaceholder = computed(() => {
  if (props.noPlaceholder) {
    return undefined;
  }

  if (props.placeholder) {
    return props.placeholder;
  }

  const key = `placeholders.${props.translationKey ?? props.name}`;

  return tExists(key) ? t(key) : undefined;
});

const cssClasses = computed(() => {
  return {
    "base-input--with-error": hasErrors.value,
    "base-input--medium": props.size === InputSizesEnum.MEDIUM,
    "base-input--large": props.size === InputSizesEnum.LARGE,
    "base-input--clean": props.variant === InputVariantsEnum.CLEAN,
    "base-input--clearable": props.clearable,
    "base-input--disabled": props.disabled,
    "base-input--inline": props.inline,
    "base-input--align-left": props.alignment === InputAlignmentsEnum.LEFT,
    "base-input--align-right": props.alignment === InputAlignmentsEnum.RIGHT,
    "base-input--align-center": props.alignment === InputAlignmentsEnum.CENTER,
    [`base-input--${props.type}`]: true,
  };
});

onMounted(() => {
  if (props.autofocus) {
    inputElement.value?.focus();
  }
});

const emit = defineEmits(["update:modelValue", "clear"]);

/*
 * An emptied number field is null rather than "": the API types these
 * `number | null`, and an empty string is a 400. Resetting to the initial value
 * would put back the very number being cleared, so a number field is set
 * instead.
 */
const clear = () => {
  if (props.type === "number") {
    handleChange(null);
    emit("update:modelValue", null);
  } else {
    handleReset();
    emit("update:modelValue", undefined);
  }
  emit("clear");
};

const onChange = (event: Event) => {
  const empty = (event.target as HTMLInputElement).value === "";

  handleChange(props.type === "number" && empty ? null : event);
  emit("update:modelValue", inputValue.value);
};

const hasValue = computed(
  () =>
    inputValue.value !== undefined &&
    inputValue.value !== null &&
    inputValue.value !== "",
);

/*
 * Options are passed through rather than fixed here. Focusing normally scrolls
 * the field into view, which is what a caller focusing a failed field further
 * down the page wants; a caller focusing into a container that is still
 * animating open does not, and passes { preventScroll: true }.
 */
const setFocus = (options?: FocusOptions) => {
  inputElement.value?.focus(options);
};

/*
 * Blur means "the reader left this field", and only then is an error worth
 * raising. A field torn out of the DOM while focused fires the same event on its
 * way out, and taking that at face value reported an empty required field on a
 * page nobody had touched yet -- signup focuses its first field on mount and
 * that subtree is then replaced, one millisecond later.
 *
 * Deferring by a tick separates them: the element a reader stepped out of is
 * still in the document, and the one that was removed is not. Both the touch and
 * the validation wait for that answer, because vee-validate keeps field state on
 * the form -- marking a torn-down field touched would outlive it and show the
 * error on whatever mounts next.
 */
const onBlur = (event: FocusEvent) => {
  const element = event.target as HTMLElement | null;

  window.setTimeout(() => {
    if (element?.isConnected) {
      handleBlur(event, true);
    }
  });
};

const slots = useSlots();

defineExpose({
  clear,
  setFocus,
});
</script>

<template>
  <div
    :key="internalId"
    class="base-input"
    :class="cssClasses"
    :data-test="`input-wrapper-${name}`"
  >
    <transition name="fade">
      <div
        v-show="!hideLabelOnEmpty || hasValue"
        v-if="innerLabel && !noLabel"
        class="field-label"
      >
        <label :for="internalId">
          <i v-if="icon" :class="icon" />
          {{ innerLabel }}
        </label>
        <!--
          Beside the label, not inside it: a focusable element inside a
          `<label>` hands its click to the control the label points at.
        -->
        <HintIcon v-if="info" :text="info" />
      </div>
    </transition>
    <div
      class="base-input__wrapper"
      :class="{
        'base-input__wrapper--with-prefix': !!prefix || !!slots.prefix,
        'base-input__wrapper--with-suffix': !!suffix || !!slots.suffix,
      }"
    >
      <!--
        The wrapper is ours, the way the suffix's is. Left inside the slot's
        default content a custom prefix replaced it, and a wrapper written in
        the consumer's template carries the consumer's scope id rather than
        this component's -- so every rule here missed it and the affix fell
        through unstyled.
      -->
      <div v-if="prefix || slots.prefix" class="base-input__prefix">
        <slot name="prefix">
          {{ prefix }}
        </slot>
      </div>
      <input
        :id="internalId"
        :aria-describedby="hasErrors ? errorId : undefined"
        ref="inputElement"
        v-tooltip.right="hasErrors && errorMessage"
        :value="inputValue"
        :placeholder="innerPlaceholder"
        :type="type"
        :data-test="`input-${name}`"
        :aria-label="innerLabel"
        :autofocus="autofocus"
        :autocomplete="autocomplete"
        :inputmode="inputmode"
        :disabled="disabled"
        :name="name"
        :min="min"
        :max="max"
        :step="innerStep"
        :class="{
          clearable,
        }"
        @input="onChange"
        @blur="onBlur"
      />
      <div v-if="suffix || slots.suffix" class="base-input__suffix">
        <slot name="suffix">
          {{ suffix }}
        </slot>
      </div>
      <div
        v-if="hasValue && clearable"
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
    <!--
      The message was in a tooltip and nowhere else: invisible until hover, and
      worth nothing to a screen reader. Its line is reserved whether or not it
      has anything to say, so validating cannot move what is below the field.

      role="alert" follows FormDateTime, which is the one control that already
      rendered a message properly -- and which borrows this same class name for
      its own element, an overlap to resolve when it moves onto the shared
      treatment.
    -->
    <p
      :id="errorId"
      class="base-input__error"
      :class="{ 'base-input__error--shown': hasErrors }"
      role="alert"
    >
      <span>{{ errorMessage }}</span>
    </p>
    <div v-if="slots.subline" class="base-input__subline">
      <slot name="subline"></slot>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
