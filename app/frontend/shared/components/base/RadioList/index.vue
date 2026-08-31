<script lang="ts">
export default {
  name: "FormRadioList",
};
</script>

<script lang="ts" setup>
import { useField } from "vee-validate";
import { v4 as uuidv4 } from "uuid";

type FormRadioListOption = {
  label: string;
  value: string;
};

type Props = {
  name: string;
  label: string;
  options: FormRadioListOption[];
  resetLabel?: string;
  modelValue?: string | number | boolean;
  inline?: boolean;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  resetLabel: undefined,
  modelValue: undefined,
  inline: true,
  disabled: false,
});

const uuid = ref(`${props.name}-${uuidv4()}`);

onMounted(() => {
  uuid.value = `${props.name}-${uuidv4()}`;
});

/*
 * Bound so the group can be told it is invalid: it was the one control in the
 * language a form had no way to reach, because it never registered a field.
 *
 * The value is mirrored rather than owned -- the template still reads
 * `modelValue`, and every existing call site is a filter form that drives it
 * that way. Registering keeps a validating form from seeing an empty field.
 */
const { value: fieldValue, errorMessage } = useField<
  string | number | boolean | undefined
>(props.name, undefined, { initialValue: props.modelValue });

watch(
  () => props.modelValue,
  () => {
    fieldValue.value = props.modelValue;
  },
);

const labelId = computed(() => `${uuid.value}-label`);

const errorId = computed(() => `${uuid.value}-error`);

const emit = defineEmits(["update:modelValue"]);

const change = (event: Event) => {
  const next = (event.target as HTMLInputElement).value;

  fieldValue.value = next;
  emit("update:modelValue", next);
};

const clear = () => {
  fieldValue.value = undefined;
  emit("update:modelValue", undefined);
};

defineExpose({
  clear,
});
</script>

<template>
  <div
    class="radio-list"
    :class="{ 'radio-list--with-error': !!errorMessage }"
    role="radiogroup"
    :aria-labelledby="labelId"
    :aria-describedby="errorMessage ? errorId : undefined"
    :aria-invalid="!!errorMessage || undefined"
  >
    <!--
      A group label, not a field label. It was a <label for> pointing at an id
      no element had, so it named nothing at all; the group is what it names,
      and aria-labelledby is how a radiogroup says so.
    -->
    <div :id="labelId" class="radio-list__label">
      {{ label }}
    </div>
    <div class="radio-list__wrapper">
      <div
        v-if="resetLabel"
        :class="{ 'radio-inline': inline }"
        class="radio-list__item"
      >
        <input
          :id="`${uuid}-reset`"
          :checked="!modelValue"
          :disabled="disabled"
          :name="name"
          type="radio"
          @change="clear"
        />
        <label :for="`${uuid}-reset`">
          {{ resetLabel }}
        </label>
      </div>
      <div
        v-for="(option, index) in options"
        :key="`${uuid}-${option.value}-${index}`"
        :class="{ 'radio-inline': inline }"
        class="radio-list__item"
      >
        <input
          :id="`${uuid}-${option.value}`"
          :checked="modelValue === option.value"
          :disabled="disabled"
          :name="name"
          :value="option.value"
          type="radio"
          @change="change"
        />
        <label :for="`${uuid}-${option.value}`" class="radio-list__label">
          {{ option.label }}
        </label>
      </div>
    </div>
    <!-- Rendered only when there is something to say -- see FormCheckbox. -->
    <p v-if="errorMessage" :id="errorId" class="radio-list__error" role="alert">
      {{ errorMessage }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
