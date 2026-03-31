<script lang="ts">
export default {
  name: "DirectUploadActions",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import DirectUploadUploader from "@/shared/components/DirectUpload/Uploader/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  uploader: InstanceType<typeof DirectUploadUploader>;
  inline?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  inline: false,
});

const { t } = useI18n();

const upload = () => {
  props.uploader.upload();
};

const comlink = useComlink();

const close = () => {
  comlink.emit("close-modal");
};

const cssClasses = computed(() => {
  return {
    "direct-upload-actions--inline": props.inline,
  };
});
</script>

<template>
  <div class="direct-upload-actions" :class="cssClasses">
    <Btn
      v-if="uploader.status === 'pending' || uploader.status === 'uploading'"
      :disabled="uploader.status === 'uploading'"
      @click="upload"
      >{{ t("directUpload.actions.upload") }}</Btn
    >
    <Btn
      v-if="
        !inline &&
        uploader.status !== 'idle' &&
        uploader.status !== 'pending' &&
        uploader.status !== 'uploading'
      "
      @click="close"
      >{{ t("directUpload.actions.close") }}</Btn
    >
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
