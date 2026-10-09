<script lang="ts">
export default {
  name: "DirectUploadActions",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import DirectUploadUploader from "@/shared/components/DirectUpload/Uploader/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  uploader: InstanceType<typeof DirectUploadUploader>;
  inline?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  inline: false,
});

// A modal footer gives its dismiss button the bare variant.
const inFooter = inject(BTN_CONTAINER, null)?.container === "footer";

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
      :variant="inFooter ? BtnVariantsEnum.BARE : undefined"
      @click="close"
      >{{ t("directUpload.actions.close") }}</Btn
    >
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
