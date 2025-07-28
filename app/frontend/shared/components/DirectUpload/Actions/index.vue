<script lang="ts">
export default {
  name: "DirectUploadActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import DirectUploadUploader from "@/shared/components/DirectUpload/Uploader/index.vue";

type Props = {
  uploader: InstanceType<typeof DirectUploadUploader>;
  variant: BtnVariantsEnum;
};

const props = defineProps<Props>();

const upload = () => {
  props.uploader.upload();
};

const chooseFile = () => {
  props.uploader.chooseFile();
};
</script>

<template>
  <Btn v-if="uploader.files.length" :variant="variant" @click="upload"
    >Upload</Btn
  >
</template>

<style lang="scss" scoped>
@import "index";
</style>
