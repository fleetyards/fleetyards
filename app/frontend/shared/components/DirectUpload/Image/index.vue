<script lang="ts">
export default {
  name: "PreviewImage",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type FileUpload } from "@/shared/components/DirectUpload/index.vue";

type Props = {
  file: FileUpload;
  multiple?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  multiple: false,
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
  return props.file.status !== "done" || !props.multiple;
});

const tooltipLabel = computed(() => {
  return isRemovable.value ? t("directUpload.previewImage.remove") : undefined;
});

const cssClasses = computed(() => {
  return {
    "preview-image--removable": isRemovable.value,
  };
});
</script>

<template>
  <LazyImage
    v-if="src"
    v-tooltip="tooltipLabel"
    :src="src"
    :alt="alt"
    shadow
    class="preview-image"
    :class="cssClasses"
  >
    <SmallLoader :loading="loading" />
    <div
      v-if="progessVisible"
      class="preview-image__progress-overlay"
      :style="{ width: progressWidth }"
    />
    <span class="preview-image__remove" v-if="isRemovable"
      ><i class="fa fa-times fa-2x"
    /></span>
  </LazyImage>
</template>

<style lang="scss" scoped>
@import "index";
</style>
