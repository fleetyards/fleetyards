<script lang="ts">
export default {
  name: "FormCheckbox",
};
</script>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { useField } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  label?: string;
  modelValue?: boolean | string | (string | number)[] | null;
  disabled?: boolean;
  /*
   * Reserves the line a field's label occupies, so this control lines up with
   * the fields beside it in a row. Off by default: on its own it would add a
   * phantom label line to every standalone checkbox in the app.
   */
  alignWithFields?: boolean;
  checkboxValue?: string | number;
  translationKey?: string;
  noPlaceholder?: boolean;
  placeholder?: string;
  slim?: boolean;
  inline?: boolean;
  partial?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  placeholder: undefined,
  modelValue: undefined,
  disabled: false,
  alignWithFields: false,
  checkboxValue: undefined,
  translationKey: undefined,
  slim: true,
  inline: false,
  partial: false,
  noLabel: false,
});

const { t } = useI18n();

const fieldOptions =
  props.checkboxValue !== undefined
    ? { type: "checkbox" as const, checkedValue: props.checkboxValue }
    : {};

const { value, errorMessage } = useField<
  boolean | string | number | (string | number)[] | null
>(props.name, undefined, fieldOptions);

const uuid = ref(`${props.name}-${uuidv4()}`);

const errorId = computed(() => `${uuid.value}-error`);

const checked = computed(() => {
  if (props.checkboxValue === undefined) {
    return value.value as boolean;
  }

  if (Array.isArray(value.value)) {
    return value.value.includes(props.checkboxValue);
  } else {
    return value.value === props.checkboxValue;
  }
});

watch(
  () => props.modelValue,
  () => {
    if (props.modelValue !== undefined) {
      value.value = props.modelValue;
    }
  },
);

onMounted(() => {
  uuid.value = `${props.name}-${uuidv4()}`;

  if (props.modelValue !== undefined) {
    value.value = props.modelValue;
  }
});

const emit = defineEmits(["update:modelValue"]);

const update = () => {
  emit("update:modelValue", value.value);
};

const innerLabel = computed(() => {
  if (props.noLabel) {
    return undefined;
  }

  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return t(`labels.${props.translationKey}`);
  }

  return t(`labels.${props.name}`);
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
</script>

<template>
  <div
    class="base-checkbox"
    :class="{
      'base-checkbox--expanded': !slim,
      'base-checkbox--inline': inline,
      'base-checkbox--partial': partial,
      'base-checkbox--with-error': !!errorMessage,
      'base-checkbox--align-with-fields': alignWithFields,
    }"
  >
    <input
      :id="uuid"
      v-model="value"
      v-tooltip.right="errorMessage"
      :aria-invalid="!!errorMessage || undefined"
      :aria-describedby="errorMessage ? errorId : undefined"
      :placeholder="innerPlaceholder"
      :name="name"
      :checked="checked"
      :disabled="disabled"
      type="checkbox"
      :value="checkboxValue"
      :data-test="`checkbox-${name}`"
      @update:model-value="update"
    />
    <label :for="uuid">
      {{ innerLabel }}
    </label>
    <!--
      Below the control rather than trailing the label as a bare text node, and
      present whether or not it has anything to say: the line is reserved so that
      showing a message cannot move what is under it.
    -->

    <!--
      Rendered only when there is something to say, unlike a field's message,
      which holds its place so an error cannot move the page.

      The reservation is worth its cost on a 43px field and not on a 24px one,
      where it doubles the control's height: it put the middle of the
      notification list's row selector on the message instead of the box, and it
      left 24px of empty space under the login form's "Remember me".
    -->
    <p
      v-if="errorMessage"
      :id="errorId"
      class="base-checkbox__error"
      role="alert"
    >
      {{ errorMessage }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
