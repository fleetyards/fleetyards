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
  checkboxValue: undefined,
  translationKey: undefined,
  slim: true,
  inline: false,
  partial: false,
  noLabel: false,
});

const { t } = useI18n();

const { value, errorMessage } = useField(props.name);

const uuid = ref(`${props.name}-${uuidv4()}`);

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
    class="base-checkbox"
    :class="{
      'base-checkbox--expanded': !slim,
      'base-checkbox--inline': inline,
      'base-checkbox--partial': partial,
    }"
  >
    <input
      :id="uuid"
      v-model="value"
      v-tooltip.right="errorMessage"
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
    {{ errorMessage }}
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
