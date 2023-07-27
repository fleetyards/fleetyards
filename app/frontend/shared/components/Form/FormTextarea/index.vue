<template>
  <div :key="uuid" class="form-input" :class="cssClasses">
    <transition name="fade">
      <label
        v-show="!hideLabelOnEmpty || inputValue"
        v-if="innerLabel && !noLabel"
        :for="id"
      >
        <i v-if="icon" :class="icon" />
        {{ innerLabel }}
      </label>
    </transition>
    <div class="form-input-wrapper">
      <textarea
        :id="uuid"
        v-model="inputValue"
        v-tooltip.right="error"
        :placeholder="innerPlaceholder"
        :data-test="`input-${id}`"
        :aria-label="innerLabel"
        :autofocus="autofocus"
        :disabled="disabled"
        :name="id"
        :rows="inputValue ? 10 : 5"
        @input="update"
        @blur="update"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import { v4 as uuidv4 } from "uuid";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

type Props = {
  id: string;
  icon?: string;
  modelValue?: string;
  error?: string;
  translationKey?: string;
  autofocus?: boolean;
  hideLabelOnEmpty?: boolean;
  label?: string;
  noLabel?: boolean;
  noPlaceholder?: boolean;
  placeholder?: string;
  clearable?: boolean;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  icon: undefined,
  modelValue: undefined,
  error: undefined,
  translationKey: undefined,
  autofocus: false,
  hideLabelOnEmpty: false,
  label: undefined,
  noLabel: false,
  noPlaceholder: false,
  placeholder: undefined,
  clearable: false,
  disabled: false,
});

const inputValue = ref<string | undefined>();

const uuid = ref(`${props.id}-${uuidv4()}`);

const i18n = inject<I18nPluginOptions>("i18n");

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return i18n?.t(`labels.${props.translationKey}`);
  }

  return i18n?.t(`labels.${props.id}`);
});

const innerPlaceholder = computed(() => {
  if (props.noPlaceholder) {
    return undefined;
  }

  if (props.placeholder) {
    return props.placeholder;
  }

  if (props.translationKey) {
    return i18n?.t(`placeholders.${props.translationKey}`);
  }

  return i18n?.t(`placeholders.${props.id}`);
});

const cssClasses = computed(() => {
  return {
    "has-error has-feedback": props.error,
    "form-input-clearable": props.clearable,
  };
});

watch(
  () => props.modelValue,
  () => {
    inputValue.value = props.modelValue;
  }
);

const inputElement = ref<HTMLInputElement | null>(null);

onMounted(() => {
  uuid.value = `${props.id}-${uuidv4()}`;
  inputValue.value = props.modelValue;

  if (props.autofocus) {
    inputElement.value?.focus();
  }
});

const emit = defineEmits(["update:modelValue", "clear"]);

const update = () => {
  emit("update:modelValue", inputValue.value);
};

const clear = () => {
  inputValue.value = undefined;

  update();

  emit("clear");
};

const setFocus = () => {
  inputElement.value?.focus();
};

defineExpose({
  clear,
  setFocus,
});
</script>

<script lang="ts">
export default {
  name: "FormTextarea",
};
</script>
