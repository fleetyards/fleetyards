<script lang="ts">
export default {
  name: "FormToggle",
};
</script>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import { useField } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  label?: string;
  modelValue?: boolean | null;
  disabled?: boolean;
  /*
   * Reserves the line a field's label occupies, so this control lines up with
   * the fields beside it in a row. Off by default: on its own it would add a
   * phantom label line to every standalone checkbox in the app.
   */
  alignWithFields?: boolean;
  translationKey?: string;
  noPlaceholder?: boolean;
  placeholder?: string;
  slim?: boolean;
  inline?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  placeholder: undefined,
  modelValue: undefined,
  disabled: false,
  alignWithFields: false,
  translationKey: undefined,
  slim: true,
  inline: false,
  noLabel: false,
});

const { t } = useI18n();

const { value, errorMessage } = useField(props.name);

const uuid = ref(`${props.name}-${uuidv4()}`);

const errorId = computed(() => `${uuid.value}-error`);

watch(
  () => props.modelValue,
  () => {
    value.value = props.modelValue;
  },
);

onMounted(() => {
  uuid.value = `${props.name}-${uuidv4()}`;

  value.value = props.modelValue;
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
    class="form-toggle"
    :class="{
      'form-toggle--expanded': !slim,
      'form-toggle--inline': inline,
      'form-toggle--with-error': !!errorMessage,
      'form-toggle--align-with-fields': alignWithFields,
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
      :disabled="disabled"
      type="checkbox"
      :data-test="`toggle-${name}`"
      @update:model-value="update"
    />
    <label :for="uuid">
      <span class="form-toggle-switch"></span>
      <span v-if="innerLabel" class="form-toggle-label">
        {{ innerLabel }}
      </span>
    </label>
    <!-- See the note in FormCheckbox: below the control, and always present. -->

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
      class="form-toggle__error"
      role="alert"
    >
      {{ errorMessage }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
