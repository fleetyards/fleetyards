<script lang="ts">
export default {
  name: "DirectUploadUploader",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import DirectUploadPreview from "@/shared/components/DirectUpload/Preview/index.vue";
import ProgressBar from "@/shared/components/ProgressBar/index.vue";
import { type Blob } from "@rails/activestorage";
import { useDirectUpload } from "@/shared/composables/useDirectUpload";
import { filesFromDataTransfer } from "@/shared/components/DirectUpload/directoryFiles";
import { v4 as uuidv4 } from "uuid";

export type FileUpload = {
  key: string;
  file: File;
  progress: number;
  status: "pending" | "uploading" | "done" | "error";
  blob?: Blob;
};

type Props = {
  multiple?: boolean;
  hideFinished?: boolean;
  transparent?: boolean;
  active?: boolean;
  allowedTypes?: string[];
  allowedSizeMb?: number;
  directUpload?: boolean;
  inputOnly?: boolean;
  directory?: boolean;
  filter?: (files: File[]) => File[];
};

const props = withDefaults(defineProps<Props>(), {
  multiple: false,
  hideFinished: false,
  transparent: false,
  active: false,
  allowedTypes: undefined,
  allowedSizeMb: undefined,
  directUpload: false,
  inputOnly: false,
  directory: false,
  filter: undefined,
});

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const files = ref<FileUpload[]>([]);
const input = ref<HTMLInputElement | undefined>();
const dropzone = ref<HTMLDivElement | undefined>();
const isDragging = ref<boolean>(false);

const handleFileSelect = async (fileList?: FileList | File[]) => {
  if (!fileList) {
    return;
  }

  if (!props.multiple || props.directUpload) {
    files.value = [];
  }

  const selected = Array.from(fileList);

  // A caller that wants only some of what was picked -- a folder of views, say
  // -- says so here, before anything is uploaded, so nothing it cannot use ends
  // up in storage as a blob nobody attaches.
  const accepted = props.filter ? props.filter(selected) : selected;
  const rejected = selected.filter((file) => !accepted.includes(file));

  accepted.forEach((file) => {
    if (files.value.some((f) => f.file === file)) {
      return;
    }

    if (props.allowedTypes && props.allowedTypes.length) {
      const fileType = file.type;

      const isAllowed = props.allowedTypes.some((type) => {
        return fileType === type;
      });

      if (!isAllowed) {
        rejected.push(file);

        // A folder carries whatever else happens to sit in it -- .DS_Store,
        // sidecar files -- and alerting on each of them would bury the upload.
        if (!props.directory) {
          displayAlert({
            text: t("errors.upload.invalidFileType", {
              filename: file.name,
              types: props.allowedTypes.join(", "),
            }),
          });
        }
        return;
      }
    }

    if (props.allowedSizeMb) {
      const fileSizeMB = file.size / (1024 * 1024);

      const isAllowed = fileSizeMB <= props.allowedSizeMb;

      if (!isAllowed) {
        rejected.push(file);

        displayAlert({
          text: t("errors.upload.fileTooLarge", {
            filename: file.name,
            size: props.allowedSizeMb.toString(),
          }),
        });
        return;
      }
    }

    files.value.push({ key: uuidv4(), file, progress: 0, status: "pending" });
  });

  // Emitted for every selection, empty included, so a caller reporting what was
  // dropped is not left showing the last pick's leftovers.
  emit("files:rejected", rejected);

  if (!props.multiple || props.directUpload) {
    await upload();
  }
};

const onDrop = async (event: DragEvent) => {
  event.preventDefault();
  event.stopPropagation();

  await handleFileSelect(await droppedFiles(event));

  isDragging.value = false;
};

// A folder is dropped as a directory entry rather than as its files, so in
// directory mode the entries are walked instead of read off `files`.
const droppedFiles = async (event: DragEvent) => {
  if (!event.dataTransfer) {
    return undefined;
  }

  if (!props.directory) {
    return event.dataTransfer.files;
  }

  return filesFromDataTransfer(event.dataTransfer);
};

const onInputChange = async (event: Event) => {
  const target = event.target as HTMLInputElement;

  await handleFileSelect(target.files || undefined);
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

const overallProgress = computed(() => {
  if (!files.value.length) {
    return 0;
  }

  const total = files.value.reduce((acc, file) => acc + file.progress, 0);
  return Math.round(total / files.value.length);
});

const upload = async () => {
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

  await Promise.all(
    files.value.map(async (file) => {
      try {
        const blob = await uploadFile(file.file, {
          progressHandler: (progress_1) => {
            file.progress = progress_1;
            file.status = "uploading";
            emit("upload:progress", overallProgress.value);
          },
        });
        file.blob = blob;
        file.status = "done";
      } catch (error) {
        file.status = "error";
        clear();
        displayAlert({
          text: (error as string) || t("errors.upload.generic"),
        });
      }
    }),
  ).then(() => {
    emit("upload:done", files.value);
  });
};

const clear = () => {
  if (input.value) {
    input.value.value = "";
  }

  files.value = [];

  emit("clear");
};

const removeFile = (file: FileUpload) => {
  files.value = files.value.filter((f) => f !== file);

  if (!props.multiple || !files.value.length) {
    emit("clear");
  }
};

const emit = defineEmits<{
  "upload:start": [files: FileUpload[]];
  "upload:progress": [progress: number];
  "upload:done": [files: FileUpload[]];
  "files:rejected": [files: File[]];
  clear: [];
}>();

const isProgressBarVisible = computed(() => {
  return (
    files.value.length &&
    props.multiple &&
    overallProgress.value > 0 &&
    overallProgress.value < 100
  );
});

const status = computed(() => {
  if (!files.value.length) {
    return "idle";
  }

  if (files.value.some((file) => file.status === "error")) {
    return "error";
  }

  if (files.value.every((file) => file.status === "done")) {
    return "done";
  }

  if (files.value.some((file) => file.status === "uploading")) {
    return "uploading";
  }

  return "pending";
});

const filteredFiles = computed(() => {
  if (props.hideFinished) {
    return files.value.filter((file) => file.status !== "done");
  }

  return files.value;
});

defineExpose({
  upload,
  chooseFile,
  files,
  status,
  clear,
});
</script>

<template>
  <div
    class="direct-upload__uploader"
    :class="{
      'direct-upload__uploader--multiple': multiple,
      'direct-upload__uploader--input-only': inputOnly,
    }"
  >
    <div
      v-if="!inputOnly && (multiple || !files.length)"
      ref="dropzone"
      class="direct-upload__dropzone"
      :class="{
        'direct-upload__dropzone--dragging': isDragging,
        'direct-upload__dropzone--active': props.active,
      }"
      @drop.prevent.stop="onDrop"
      @dragover.prevent="dragover"
      @dragleave.prevent="dragleave"
      @dragend.prevent="dragend"
    >
      <i class="fa-light fa-cloud-upload"></i>
      <span class="direct-upload__dropzone-title">
        <template v-if="directory">
          {{ t("directUpload.dropzone.textDirectory") }}
        </template>
        <template v-else-if="multiple">
          {{ t("directUpload.dropzone.textMultiple") }}
        </template>
        <template v-else>
          {{ t("directUpload.dropzone.text") }}
        </template>
      </span>
      <span>{{ t("directUpload.dropzone.or") }}</span>
      <Btn @click="chooseFile" :variant="BtnVariantsEnum.BARE">{{
        directory
          ? t("directUpload.dropzone.browseDirectory")
          : t("directUpload.dropzone.browse")
      }}</Btn>
    </div>
    <input
      ref="input"
      type="file"
      class="direct-upload__input"
      :multiple="props.multiple"
      :webkitdirectory="props.directory || null"
      @change="onInputChange"
    />
    <Transition name="fade">
      <ProgressBar
        :progress="overallProgress"
        v-if="isProgressBarVisible && !inputOnly"
      />
    </Transition>
    <template v-if="!props.directUpload && !inputOnly">
      <div v-if="props.multiple" class="direct-upload__preview-files">
        <TransitionGroup name="fade">
          <DirectUploadPreview
            v-for="file in filteredFiles"
            :key="file.key"
            class="direct-upload__file"
            :file="file"
            :transparent="transparent"
            multiple
            @click="file.status !== 'done' && removeFile(file)"
          />
        </TransitionGroup>
      </div>
      <div v-else-if="files.length" class="direct-upload__preview-file">
        <TransitionGroup name="fade">
          <DirectUploadPreview
            v-for="file in files"
            :key="file.key"
            class="direct-upload__file"
            :file="file"
            :transparent="transparent"
            @click="removeFile(file)"
          />
        </TransitionGroup>
      </div>
    </template>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
