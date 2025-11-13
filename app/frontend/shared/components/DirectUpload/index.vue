<script lang="ts">
export default {
  name: "DirectUpload",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import DirectUploadUploader, {
  type FileUpload as InternalFileUpload,
} from "@/shared/components/DirectUpload/Uploader/index.vue";
import DirectUploadActions from "@/shared/components/DirectUpload/Actions/index.vue";
import { useComlink } from "@/shared/composables/useComlink";

export type FileUpload = InternalFileUpload;

type Props = {
  multiple?: boolean;
  inline?: boolean;
  hideFinished?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  multiple: false,
  inline: false,
  hideFinished: false,
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
  "upload:start": [files: FileUpload[]];
  "upload:progress": [progress: number];
  "upload:done": [files: FileUpload[]];
  clear: [];
}>();

const handleUploadStart = (files: FileUpload[]) => {
  emit("upload:start", files);
};

const handleUploadProgress = (progress: number) => {
  emit("upload:progress", progress);
};

const handleUploadDone = (files: FileUpload[]) => {
  emit("upload:done", files);
};

const handleClear = () => {
  emit("clear");
};

const cssClasses = computed(() => {
  return {
    "direct-upload--single": !props.multiple,
  };
});
</script>

<template>
  <div class="direct-upload" :class="cssClasses">
    <Btn v-if="multiple && !inline" @click="openModal">Choose files</Btn>
    <template v-else>
      <DirectUploadUploader
        ref="uploader"
        :multiple="multiple"
        :hide-finished="hideFinished"
        @upload:done="handleUploadDone"
        @upload:progress="handleUploadProgress"
        @upload:start="handleUploadStart"
        @clear="handleClear"
      />
      <DirectUploadActions
        v-if="uploader && multiple"
        :uploader="uploader"
        :inline="inline"
      />
    </template>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
