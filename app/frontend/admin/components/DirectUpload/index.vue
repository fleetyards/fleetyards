<script lang="ts" setup>
import DirectUploadUploader from "@/admin/components/DirectUpload/Uploader/index.vue";
import DirectUploadActions from "@/admin/components/DirectUpload/Actions/index.vue";
import { type Blob } from "@rails/activestorage";

const uploader = ref<InstanceType<typeof DirectUploadUploader>>();

const emit = defineEmits<{
  "upload:start": [files: File[]];
  "upload:progress": [progress: number];
  "upload:done": [files: Blob[]];
  clear: [];
}>();

const handleUploadStart = (files: File[]) => {
  emit("upload:start", files);
};

const handleUploadProgress = (progress: number) => {
  emit("upload:progress", progress);
};

const handleUploadDone = (files: Blob[]) => {
  console.log(files);
  emit("upload:done", files);
};

const handleClear = () => {
  emit("clear");
};
</script>

<template>
  <div class="direct-upload">
    <DirectUploadUploader
      ref="uploader"
      :multiple="false"
      @upload:done="handleUploadDone"
      @upload:progress="handleUploadProgress"
      @upload:start="handleUploadStart"
      @clear="handleClear"
    />
    <DirectUploadActions v-if="uploader" :uploader="uploader" />
  </div>
</template>

<script lang="ts">
export default {
  name: "DirectUpload",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
