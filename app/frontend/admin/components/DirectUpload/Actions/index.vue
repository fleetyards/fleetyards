<script lang="ts" setup>
import DirectUploadUploader from "@/admin/components/DirectUpload/Uploader/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";

type Props = {
  uploader: InstanceType<typeof DirectUploadUploader>;
};

const props = defineProps<Props>();

const upload = () => {
  props.uploader.upload();
};
</script>

<script lang="ts">
export default {
  name: "DirectUploadActions",
};
</script>

<template>
  <Btn v-if="uploader.files.length" @click.native="upload">Upload</Btn>
</template>

<style lang="scss" scoped>
@import "index";
</style>
