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
  previewSrc?: string;
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
  avatar?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  src: undefined,
  file: undefined,
  icon: undefined,
  modelValue: undefined,
  previewSrc: undefined,
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
  avatar: false,
});

watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue !== inputValue.value) {
      resetField({
        value: newValue,
      });
    }
  },
);

const { t } = useI18n();

const inputElement = ref<HTMLInputElement | undefined>();

const id = ref(`${props.name}-${uuidv4()}`);

const errorId = computed(() => `${id.value}-error`);

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

// Whether this input's own upload is showing what it uploaded. A value set from
// outside -- the views folder filling the whole form -- is not that, and hiding
// the picture for it left the input blank.
const uploadedHere = ref(false);

/*
 * A failed upload used to reach nobody. The uploader caught it, cleared itself
 * and raised a toast, and the only event it emitted afterwards was
 * `upload:done` -- so this control never learned, and stood there empty and
 * apparently fine while a toast said "Error creating Blob" somewhere else.
 *
 * Held separately from the validation errors because it is not one: it says the
 * file did not get there, not that the value is wrong.
 */
const uploadFailed = ref(false);

const onUploadError = () => {
  uploadFailed.value = true;
};

const hasErrors = computed(() => {
  return errors.value.length || uploadFailed.value;
});

const shownError = computed(() =>
  uploadFailed.value ? t("errors.upload.generic") : errorMessage.value,
);

const cssClasses = computed(() => {
  return {
    "base-image-input--with-error": hasErrors.value,
    "base-image-input--disabled": props.disabled,
    "base-image-input--avatar": props.avatar,
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
  uploadedHere.value = false;

  if (inputValue.value) {
    directUpload.value?.clear();
  } else {
    handleReset();
    internalSrc.value = undefined;
    emit("update:modelValue", null);
  }
};

const onUploadDone = (files: FileUpload[]) => {
  uploadFailed.value = false;

  if (!files.length || !files[0].blob) {
    return;
  }

  uploadedHere.value = true;
  inputValue.value = files[0].blob.signed_id;
  emit("update:modelValue", files[0].blob.signed_id);
};

const onUploadClear = () => {
  uploadedHere.value = false;
  uploadFailed.value = false;

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
  uploadedHere.value = false;

  directUpload.value?.clear();

  internalSrc.value = isHolo.value ? props.file?.url : props.file?.smallUrl;

  if (inputValue.value) {
    resetField({ value: undefined });
    emit("update:modelValue", undefined);
  }
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

// The types this input takes, however they were passed.
const allowedTypeList = computed(() => {
  if (!props.allowedTypes) {
    return [];
  }

  return Array.isArray(props.allowedTypes)
    ? props.allowedTypes
    : [props.allowedTypes];
});

// A holo is drawn by its viewer rather than shown as a picture, so a previewSrc
// for one is a local file to load, not an image to display.
const previewHoloModel = computed(() => {
  if (
    !props.previewSrc ||
    !allowedTypeList.value.includes(AllowedFileTypes.HOLO)
  ) {
    return undefined;
  }

  return {
    path: props.previewSrc,
  };
});

const holoModel = computed(() => {
  if (props.file?.url && isHolo.value) {
    return {
      path: props.file.url,
    };
  }

  return undefined;
});

// The dropzone is only pinned open while there is nothing to look at. A
// previewSrc counts: the folder upload fills the whole form that way, and
// forcing the overlay on top of it hid every picture it just set.
const hasPreview = computed(() => {
  return uploadedHere.value || !!props.previewSrc || !!internalSrc.value;
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
      <template v-if="!uploadedHere">
        <!-- A value set from outside brings its own file: the upload that
             filled it happened elsewhere, so this input has none to show. -->
        <HoloViewer
          v-if="previewHoloModel"
          :controllable="false"
          :models="[previewHoloModel]"
          inline
        />
        <LazyImage
          v-else-if="previewSrc"
          v-tooltip.right="hasErrors && errorMessage"
          :src="previewSrc"
          :transparent="transparent || avatar"
          :shadow="!transparent && !avatar"
        />
        <LazyImage
          v-else-if="(isImage || isPdf) && internalSrc"
          v-tooltip.right="hasErrors && errorMessage"
          :src="internalSrc"
          :transparent="transparent || avatar"
          :shadow="!transparent && !avatar"
        />
        <HoloViewer
          v-else-if="holoModel"
          :controllable="false"
          :models="[holoModel]"
          inline
        />
        <i v-else class="fa-solid fa-7x" :class="fileTypeIconClass" />
      </template>
      <DirectUpload
        v-if="!disabled"
        ref="directUpload"
        class="base-image-input__direct-upload"
        :multiple="false"
        :allowed-types="fileTypeMap[props.allowedTypes as AllowedFileTypes]"
        :allowed-size-mb="props.allowedSizeMb"
        :transparent="transparent || avatar"
        :active="!hasPreview"
        @upload:done="onUploadDone"
        @upload:error="onUploadError"
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
      <Btn
        v-if="clearable && (internalSrc || inputValue)"
        v-tooltip="clearLabel"
        @click="clear"
        class="base-image-input__clear"
        variant="bare"
      >
        <i class="fa fa-times" />
      </Btn>
    </div>
    <!-- See the note in FormInput: below the control, and always present. -->
    <p
      :id="errorId"
      class="base-image-input__error"
      :class="{ 'base-image-input__error--shown': hasErrors }"
      role="alert"
    >
      <span>{{ shownError }}</span>
    </p>
    <div v-if="slots.subline" class="base-image-input__subline">
      <slot name="subline"></slot>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
