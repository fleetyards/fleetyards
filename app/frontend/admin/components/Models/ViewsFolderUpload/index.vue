<script lang="ts">
export default {
  name: "ModelsViewsFolderUpload",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import DirectUpload, {
  type FileUpload,
} from "@/shared/components/DirectUpload/index.vue";
import {
  AllowedFileTypes,
  fileTypeMap,
} from "@/shared/components/DirectUpload/types";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import {
  mapViewFiles,
  type MappedView,
  type ViewField,
} from "@/admin/components/Models/ViewsFolderUpload/mapping";

type PlannedView = MappedView & { file: File };

const { t } = useI18n();

const emit = defineEmits<{
  selected: [previews: Partial<Record<ViewField, string>>];
  mapped: [views: Partial<Record<ViewField, string>>];
}>();

const plan = ref<PlannedView[]>([]);
const previews = new Map<ViewField, string>();
const ignored = ref<string[]>([]);
const uploaded = ref<File[]>([]);
const uploading = ref(false);

// The file input reports the folder in webkitRelativePath, a drop does not.
const nameOf = (file: File) => file.webkitRelativePath || file.name;

const basename = (filename: string) => filename.split("/").pop() || filename;

// Runs before a single byte goes up, so a folder's odds and ends never become
// blobs that no view is ever attached to.
const filterViews = (files: File[]) => {
  const { matched } = mapViewFiles(files, nameOf);

  plan.value = matched.map(({ field, filename, item }) => ({
    field,
    filename: basename(filename),
    file: item,
  }));
  uploaded.value = [];

  // A signed id only arrives once the upload finishes, but the picture can be
  // shown from the local file at once, so no input sits there empty meanwhile.
  plan.value.forEach(({ field, file }) => {
    const previous = previews.get(field);

    if (previous) {
      URL.revokeObjectURL(previous);
    }

    previews.set(field, URL.createObjectURL(file));
  });

  emit("selected", Object.fromEntries(previews));

  return matched.map(({ item }) => item);
};

onBeforeUnmount(() => {
  previews.forEach((url) => URL.revokeObjectURL(url));
  previews.clear();
});

const onFilesRejected = (files: File[]) => {
  ignored.value = files.map((file) => basename(nameOf(file)));
};

const onUploadStart = () => {
  uploading.value = plan.value.length > 0;
};

const onUploadDone = (files: FileUpload[]) => {
  uploading.value = false;
  uploaded.value = files.filter((file) => !!file.blob).map((file) => file.file);

  const views = plan.value.flatMap(({ field, file }): [ViewField, string][] => {
    const upload = files.find((candidate) => candidate.file === file);

    return upload?.blob ? [[field, upload.blob.signed_id]] : [];
  });

  emit("mapped", Object.fromEntries(views));
};

const isUploaded = (view: PlannedView) => uploaded.value.includes(view.file);
</script>

<template>
  <div class="views-folder-upload">
    <p class="views-folder-upload__hint">
      {{ t("texts.admin.models.viewsFolder.hint") }}
    </p>

    <DirectUpload
      multiple
      inline
      directory
      direct-upload
      :allowed-types="fileTypeMap[AllowedFileTypes.IMAGE]"
      :filter="filterViews"
      @upload:start="onUploadStart"
      @upload:done="onUploadDone"
      @files:rejected="onFilesRejected"
    />

    <template v-if="plan.length">
      <p class="views-folder-upload__summary">
        {{
          uploading
            ? t("texts.admin.models.viewsFolder.uploading", {
                count: plan.length,
              })
            : t("texts.admin.models.viewsFolder.matched", {
                count: plan.length,
              })
        }}
      </p>
      <ul class="views-folder-upload__matched">
        <li v-for="view in plan" :key="view.field">
          <i
            v-if="isUploaded(view)"
            class="fa-duotone fa-circle-check text-success"
          />
          <SmallLoader v-else loading />
          <span>{{ t(`labels.model.${view.field}`) }}</span>
          <span class="views-folder-upload__filename">{{ view.filename }}</span>
        </li>
      </ul>
    </template>

    <p v-if="ignored.length" class="views-folder-upload__ignored">
      {{
        t("texts.admin.models.viewsFolder.ignored", {
          files: ignored.join(", "),
        })
      }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
