<script lang="ts">
export default {
  name: "DirectUploadUploader",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import PreviewImage from "@/shared/components/DirectUpload/Image/index.vue";
import { type Blob } from "@rails/activestorage";
import { useDirectUpload } from "@/shared/composables/useDirectUpload";

type Props = {
  multiple?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  multiple: false,
});

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const files = ref<File[]>([]);
const input = ref<HTMLInputElement | undefined>();
const dropzone = ref<HTMLDivElement | undefined>();
const isDragging = ref<boolean>(false);

const handleFileSelect = (fileList?: FileList) => {
  if (!fileList) {
    return;
  }

  if (!props.multiple) {
    files.value = [];
  }

  Array.from(fileList).forEach((file) => {
    files.value.includes(file) || files.value.push(file);
  });

  if (!props.multiple) {
    upload();
  }
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

  if (files.value?.length > 1 && !props.multiple) {
    displayAlert({
      text: t("errors.upload.oneFile"),
    });
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
        displayAlert({
          text: (error as string) || t("errors.upload.generic"),
        });
      },
    });
  });

  emit("upload:done", []);
};

const clear = () => {
  if (input.value) {
    (input.value as HTMLInputElement).value = "";
  }

  files.value = [];

  emit("clear");
};

const removeFile = (file: File) => {
  files.value = files.value.filter((f) => f !== file);

  if (!props.multiple || !files.value.length) {
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

<template>
  <div
    class="direct-upload__uploader"
    :class="{
      'direct-upload__uploader--multiple': multiple,
    }"
  >
    <div
      v-if="multiple || !files.length"
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
        <template v-if="multiple">
          {{ t("directUpload.dropzone.textMultiple") }}
        </template>
        <template v-else>
          {{ t("directUpload.dropzone.text") }}
        </template>
      </span>
      <span>{{ t("directUpload.dropzone.or") }}</span>
      <Btn :variant="BtnVariantsEnum.LINK" text-inline @click="chooseFile">{{
        t("directUpload.dropzone.browse")
      }}</Btn>
    </div>
    <input
      ref="input"
      type="file"
      class="direct-upload__input"
      :multiple="multiple"
      @change="onInputChange"
    />
    <div v-if="multiple" class="direct-upload__preview-files">
      <PreviewImage
        v-for="file in files"
        :key="file.name"
        class="direct-upload__file"
        :file="file"
        @click="removeFile(file)"
      />
    </div>
    <div v-else-if="files.length" class="direct-upload__preview-file">
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
