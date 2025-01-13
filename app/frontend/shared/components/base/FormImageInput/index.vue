<script lang="ts">
export default {
  name: "FormImageInput",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import DirectUpload from "@/shared/components/DirectUpload/index.vue";
import { useField } from "vee-validate";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";
import { type Blob } from "@rails/activestorage";

type Props = {
  name: string;
  image?: string;
  icon?: string;
  modelValue?: string | number;
  translationKey?: string;
  autofocus?: boolean;
  autocomplete?: string;
  hideLabelOnEmpty?: boolean;
  label?: string;
  min?: number;
  max?: number;
  step?: number;
  noLabel?: boolean;
  noPlaceholder?: boolean;
  placeholder?: string;
  clearable?: boolean;
  disabled?: boolean;
  inline?: boolean;
  prefix?: string;
  suffix?: string;
};

const props = withDefaults(defineProps<Props>(), {
  image: undefined,
  icon: undefined,
  modelValue: undefined,
  translationKey: undefined,
  autofocus: false,
  autocomplete: undefined,
  hideLabelOnEmpty: false,
  label: undefined,
  min: undefined,
  max: undefined,
  step: 0.01,
  noLabel: false,
  noPlaceholder: false,
  placeholder: undefined,
  clearable: false,
  disabled: false,
  inline: false,
  prefix: undefined,
  suffix: undefined,
});

watch(
  () => props.modelValue,
  () => {
    resetField({
      value: props.modelValue,
    });
  },
);

const { t } = useI18n();

const inputElement = ref<HTMLInputElement | undefined>();

const id = ref(`${props.name}-${uuidv4()}`);

const innerLabel = computed(() => {
  if (props.label) {
    return props.label;
  }

  if (props.translationKey) {
    return t(`labels.${props.translationKey}`);
  }

  return t(`labels.${props.name}`);
});

const initialValue = ref(props.modelValue);

const {
  value: inputValue,
  errorMessage,
  errors,
  handleChange,
  handleReset,
  resetField,
} = useField(props.name, undefined, {
  initialValue: initialValue.value,
  label: innerLabel.value,
});

const hasErrors = computed(() => {
  return errors.value.length;
});

const cssClasses = computed(() => {
  return {
    "base-input--with-error": hasErrors.value,
    "base-input--disabled": props.disabled,
  };
});

onMounted(() => {
  id.value = `${props.name}-${uuidv4()}`;

  if (props.autofocus) {
    inputElement.value?.focus();
  }
});

const emit = defineEmits(["update:modelValue"]);

const clear = () => {
  handleReset();
  emit("update:modelValue", undefined);
};

const onChange = (event: Event) => {
  handleChange(event);
  emit("update:modelValue", inputValue.value);
};

const onUploadDone = (files: Blob[]) => {
  if (!files.length) {
    return;
  }

  inputValue.value = files[0].signed_id;
};

const onUploadClear = () => {
  resetField({
    value: initialValue.value,
  });
};

const slots = useSlots();

defineExpose({
  clear,
});
</script>

<template>
  <div :key="id" class="base-image-input" :class="cssClasses">
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
    <div class="base-image-input__wrapper">
      <LazyImage
        v-tooltip.right="hasErrors && errorMessage"
        :src="image"
        shadow
      >
        <DirectUpload
          :multiple="false"
          @upload:done="onUploadDone"
          @clear="onUploadClear"
        />
      </LazyImage>

      <input
        :id="id"
        ref="inputElement"
        :value="inputValue"
        type="text"
        :data-test="`input-${name}`"
        :disabled="disabled"
        :name="name"
        hidden
        @input="onChange"
      />
    </div>
    <div v-if="slots.subline" class="base-image-input__subline">
      <slot name="subline"></slot>
    </div>

    {{ inputValue }}
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
