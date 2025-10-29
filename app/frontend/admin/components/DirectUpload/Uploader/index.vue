<script lang="ts" setup>
import { type Blob } from "@rails/activestorage";
import PreviewImage from "@/admin/components/DirectUpload/Image/index.vue";
import { useDirectUpload } from "@/admin/composables/useDirectUpload";
import { useI18n } from "@/frontend/composables/useI18n";
import Btn from "@/frontend/core/components/Btn/index.vue";

const { t } = useI18n();

const files = ref<File[]>([]);
const input = ref<HTMLInputElement | undefined>();
const dropzone = ref<HTMLDivElement | undefined>();
const isDragging = ref<boolean>(false);

const handleFileSelect = (fileList?: FileList) => {
  if (!fileList) {
    return;
  }

  Array.from(fileList).forEach((file) => {
    if (!files.value.includes(file)) {
      files.value.push(file);
    }
  });

  upload();
};

const onDrop = (event: DragEvent) => {
  event.preventDefault();
  event.stopPropagation();

  handleFileSelect(event.dataTransfer?.files);

  isDragging.value = false;
};

const onInputChange = (event: Event) => {
  const target = event.target as HTMLInputElement;

  handleFileSelect(target.files || undefined);
};

const dragover = (event: DragEvent) => {
  event.preventDefault();
  event.stopPropagation();

  isDragging.value = true;
};

const dragleave = (event: DragEvent) => {
  event.preventDefault();
  event.stopPropagation();

  if (event.target === dropzone.value) {
    isDragging.value = false;
  }
};

const dragend = (event: DragEvent) => {
  event.preventDefault();
  event.stopPropagation();

  isDragging.value = false;
};

const chooseFile = () => {
  input.value?.click();
};

const { uploadFile } = useDirectUpload();

const upload = () => {
  emit("upload:start", files.value);

  if (!files.value.length) {
    return;
  }

  files.value.forEach((file) => {
    uploadFile(file, {
      successHandler: (blob) => {
        emit("upload:done", [blob]);
      },
      progressHandler: (progress) => {
        emit("upload:progress", progress);
      },
      errorHandler: (error) => {
        clear();
      },
    });
  });

  emit("upload:done", []);
};

const clear = () => {
  if (input.value) {
    input.value.value = "";
  }

  files.value = [];

  emit("clear");
};

const removeFile = (file: File) => {
  files.value = files.value.filter((f) => f !== file);

  if (!files.value.length) {
    emit("clear");
  }
};

const emit = defineEmits<{
  "upload:start": [files: File[]];
  "upload:progress": [progress: number];
  "upload:done": [files: Blob[]];
  clear: [];
}>();

defineExpose({
  upload,
  chooseFile,
  files,
});
</script>

<script lang="ts">
export default {
  name: "DirectUploadUploader",
};
</script>

<template>
  <div class="direct-upload__uploader">
    <div
      v-if="!files.length"
      ref="dropzone"
      class="direct-upload__dropzone"
      :class="{
        'direct-upload__dropzone--dragging': isDragging,
      }"
      @drop.prevent.stop="onDrop"
      @dragover.prevent="dragover"
      @dragleave.prevent="dragleave"
      @dragend.prevent="dragend"
    >
      <i class="fal fa-cloud-upload"></i>
      <span class="direct-upload__dropzone-title">
        {{ t("directUpload.dropzone.text") }}
      </span>
      <span>{{ t("directUpload.dropzone.or") }}</span>
      <Btn text-inline @click.native="chooseFile">{{
        t("directUpload.dropzone.browse")
      }}</Btn>
    </div>
    <input
      ref="input"
      type="file"
      class="direct-upload__input"
      @change="onInputChange"
    />
    <div v-if="files.length" class="direct-upload__preview-file">
      <PreviewImage
        v-for="file in files"
        :key="file.name"
        class="direct-upload__file"
        :file="file"
        @click="removeFile(file)"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
