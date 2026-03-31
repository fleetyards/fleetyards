<script lang="ts">
export default {
  name: "DirectUploadPreview",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import HoloViewer from "@/shared/components/HoloViewer/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type FileUpload } from "@/shared/components/DirectUpload/index.vue";
import { fileTypeMap } from "../types";

type Props = {
  file: FileUpload;
  multiple?: boolean;
  transparent?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  multiple: false,
  transparent: false,
});

const { t } = useI18n();

const src = ref<string | undefined>();

const alt = computed(() => props.file.file.name);

const reader = new FileReader();

onMounted(() => {
  reader.onload = (event) => {
    src.value = event.target?.result as string;
  };

  reader.readAsDataURL(props.file.file);
});

const progressWidth = computed(() => {
  return `${100 - props.file.progress}%`;
});

const progessVisible = computed(() => {
  return props.file.progress < 100;
});

const loading = computed(() => {
  return progessVisible.value && props.file.progress > 0;
});

const isRemovable = computed(() => {
  return props.file.status !== "done" && props.multiple;
});

const tooltipLabel = computed(() => {
  return isRemovable.value ? t("directUpload.previewImage.remove") : undefined;
});

const cssClasses = computed(() => {
  return {
    "preview--removable": isRemovable.value,
  };
});

const progressCssClasses = computed(() => {
  return {
    "preview__progress-overlay": true,
    "preview__progress-overlay--transparent": props.transparent,
  };
});

const isImage = computed(() => {
  return fileTypeMap.image.includes(props.file.file.type || "");
});

const isHolo = computed(() => {
  return fileTypeMap.holo.includes(props.file.file.type || "");
});

const fileTypeIconClass = computed(() => {
  if (fileTypeMap.holo.includes(props.file.file.type || "")) {
    return "fa-cube"; // Note: FontAwesome does not have a holo icon, replace with appropriate icon
  }
  if (fileTypeMap.image.includes(props.file.file.type || "")) {
    return "fa-image";
  }
  if (fileTypeMap.video.includes(props.file.file.type || "")) {
    return "fa-video";
  }
  if (fileTypeMap.audio.includes(props.file.file.type || "")) {
    return "fa-audio-description";
  }
  if (fileTypeMap.pdf.includes(props.file.file.type || "")) {
    return "fa-file-pdf";
  }
  return "fa-file";
});

const holoModel = computed(() => {
  if (src.value && isHolo.value) {
    return {
      path: src.value,
    };
  }

  return undefined;
});
</script>

<template>
  <div v-if="src" class="preview" :class="cssClasses">
    <LazyImage
      v-if="isImage"
      v-tooltip="tooltipLabel"
      :src="src"
      :alt="alt"
      :transparent="transparent"
      :shadow="!transparent"
    />
    <HoloViewer
      v-else-if="holoModel"
      :controllable="false"
      :models="[holoModel]"
      inline
    />
    <i v-else class="fa-solid fa-7x" :class="fileTypeIconClass" />
    <div class="preview__name" v-if="!isImage && !isHolo">
      {{ file.file.name }}
    </div>
    <SmallLoader :loading="loading" />
    <div
      v-if="progessVisible"
      :class="progressCssClasses"
      :style="{ width: progressWidth }"
    />
    <span class="preview__remove" v-if="isRemovable"
      ><i class="fa fa-times fa-2x"
    /></span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
