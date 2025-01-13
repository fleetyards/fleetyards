<script lang="ts">
export default {
  name: "DirectUpload",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import DirectUploadUploader from "@/shared/components/DirectUpload/Uploader/index.vue";
import DirectUploadActions from "@/shared/components/DirectUpload/Actions/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { type Blob } from "@rails/activestorage";

type Props = {
  multiple?: boolean;
};

withDefaults(defineProps<Props>(), {
  multiple: false,
});

const uploader = ref<InstanceType<typeof DirectUploadUploader>>();

const comlink = useComlink();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/shared/components/DirectUpload/Modal/index.vue"),
    wide: true,
  });
};

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
  emit("upload:done", files);
};

const handleClear = () => {
  emit("clear");
};
</script>

<template>
  <Btn v-if="multiple" @click="openModal">Choose files</Btn>
  <div v-else class="direct-upload">
    <DirectUploadUploader
      ref="uploader"
      :multiple="false"
      @upload:done="handleUploadDone"
      @upload:progress="handleUploadProgress"
      @upload:start="handleUploadStart"
      @clear="handleClear"
    />
    <DirectUploadActions
      v-if="uploader"
      :variant="BtnVariantsEnum.LINK"
      :uploader="uploader"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
