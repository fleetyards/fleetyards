<script lang="ts">
export default {
  name: "FormFileInput",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import DirectUpload, {
  type FileUpload,
} from "@/shared/components/DirectUpload/index.vue";
import {
  AllowedFileTypes,
  fileTypeMap,
} from "@/shared/components/DirectUpload/types";
import { useField } from "vee-validate";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import { type MediaFile } from "@/services/fyApi";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";

type Props = {
  name: string;
  file?: MediaFile;
  icon?: string;
  modelValue?: string | null;
  translationKey?: string;
  autofocus?: boolean;
  autocomplete?: string;
  hideLabelOnEmpty?: boolean;
  allowedTypes?: AllowedFileTypes | AllowedFileTypes[];
  allowedSizeMb?: number;
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
  transparent?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  src: undefined,
  file: undefined,
  icon: undefined,
  modelValue: undefined,
  translationKey: undefined,
  autofocus: false,
  autocomplete: undefined,
  hideLabelOnEmpty: false,
  allowedTypes: undefined,
  allowedSizeMb: undefined,
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
  transparent: false,
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

const {
  value: inputValue,
  errorMessage,
  errors,
  handleReset,
  resetField,
} = useField(props.name, undefined, {
  initialValue: props.modelValue,
  label: innerLabel.value,
});

const isImage = computed(() => {
  return fileTypeMap.image.includes(props.file?.contentType || "");
});

const isPdf = computed(() => {
  return fileTypeMap.pdf.includes(props.file?.contentType || "");
});

const isHolo = computed(() => {
  return fileTypeMap.holo.includes(props.file?.contentType || "");
});

const internalSrc = ref<string>();

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
  if (inputValue.value) {
    directUpload.value?.clear();
  } else {
    handleReset();
    internalSrc.value = undefined;
    emit("update:modelValue", null);
  }
};

const onUploadDone = (files: FileUpload[]) => {
  if (!files.length || !files[0].blob) {
    return;
  }

  inputValue.value = files[0].blob.signed_id;
};

const onUploadClear = () => {
  resetField({
    value: props.modelValue,
  });
};

const fileTypeIconClass = computed(() => {
  if (
    props.allowedTypes?.length === 1 ||
    typeof props.allowedTypes === "string"
  ) {
    const type = Array.isArray(props.allowedTypes)
      ? props.allowedTypes[0]
      : props.allowedTypes;
    switch (type) {
      case "image":
        return "fa-image";
      case "video":
        return "fa-video";
      case "audio":
        return "fa-audio-description";
      case "pdf":
        return "fa-file-pdf";
      case "holo":
        return "fa-cube"; // Note: FontAwesome does not have a holo icon, replace with appropriate icon
      default:
        return "fa-file";
    }
  } else {
    return "fa-file";
  }
});

const slots = useSlots();

const directUpload = ref<InstanceType<typeof DirectUpload>>();

const setup = () => {
  directUpload.value?.clear();

  internalSrc.value = isHolo.value ? props.file?.url : props.file?.smallUrl;
};

onMounted(() => {
  setup();
});

watch(
  () => props.file,
  () => {
    setup();
  },
);

const holoModel = computed(() => {
  if (props.file?.url && isHolo.value) {
    return {
      path: props.file.url,
    };
  }

  return undefined;
});

const clearLabel = computed(() => {
  if (inputValue.value) {
    return t("actions.reset");
  }

  return t("actions.clear");
});

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
      <template v-if="!inputValue">
        <LazyImage
          v-if="(isImage || isPdf) && internalSrc"
          v-tooltip.right="hasErrors && errorMessage"
          :src="internalSrc"
          :transparent="transparent"
          :shadow="!transparent"
        />
        <HoloViewer
          v-else-if="holoModel"
          :controllable="false"
          :models="[holoModel]"
          inline
        />
        <i v-else class="fas fa-7x" :class="fileTypeIconClass" />
      </template>
      <DirectUpload
        v-if="!disabled"
        ref="directUpload"
        class="base-image-input__direct-upload"
        :multiple="false"
        :allowed-types="fileTypeMap[props.allowedTypes as AllowedFileTypes]"
        :allowed-size-mb="props.allowedSizeMb"
        :transparent="transparent"
        :active="!internalSrc"
        @upload:done="onUploadDone"
        @clear="onUploadClear"
      />
      <input
        :id="id"
        ref="inputElement"
        :value="inputValue"
        type="text"
        :data-test="`input-${name}`"
        :disabled="disabled"
        :name="name"
        hidden
      />
    </div>
    <div v-if="slots.subline" class="base-image-input__subline">
      <slot name="subline"></slot>
    </div>
    <Btn
      v-if="clearable && (internalSrc || inputValue)"
      variant="link"
      v-tooltip="clearLabel"
      inline
      @click="clear"
      class="clear"
    >
      <i class="fa fa-times" />
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
