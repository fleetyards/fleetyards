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
  isHoloField,
  mapFolderFiles,
  type FolderField,
  type MappedFile,
} from "@/admin/components/Models/ViewsFolderUpload/mapping";

type PlannedFile = MappedFile & { file: File };

const { t } = useI18n();

const emit = defineEmits<{
  selected: [previews: Partial<Record<FolderField, string>>];
  mapped: [fields: Partial<Record<FolderField, string>>];
}>();

const plan = ref<PlannedFile[]>([]);
const ignored = ref<string[]>([]);
const uploaded = ref<File[]>([]);
const uploading = ref(false);
const previews = new Map<FolderField, string>();

// The file input reports the folder in webkitRelativePath, a drop does not.
const nameOf = (file: File) => file.webkitRelativePath || file.name;

const basename = (filename: string) => filename.split("/").pop() || filename;

// What the preview beside a single upload has always handed the holo viewer,
// and what three's FileLoader decodes where it stands rather than fetching. The
// pictures are happy behind a blob: URL; a model behind one was not.
const readDataUrl = (file: File) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(reader.error);

    reader.readAsDataURL(file);
  });

const publishPreviews = () => {
  emit("selected", Object.fromEntries(previews));
};

const forget = (field: FolderField) => {
  const previous = previews.get(field);

  if (previous?.startsWith("blob:")) {
    URL.revokeObjectURL(previous);
  }

  previews.delete(field);
};

// Runs before a single byte goes up, and it is the only gate: a name that spells
// out a field, with the extension that field takes, or the file stays where it
// is. So a folder's odds and ends never become blobs no view is attached to.
const filterFolder = (files: File[]) => {
  const { matched } = mapFolderFiles(files, nameOf);

  plan.value = matched.map(({ field, filename, item }) => ({
    field,
    filename: basename(filename),
    file: item,
  }));
  uploaded.value = [];

  // A signed id only arrives once the upload finishes, but the file itself can
  // be shown at once -- a picture as a picture, a holo in its viewer -- so no
  // input sits there empty meanwhile. Reading a holo takes a moment, so it
  // lands in a second round.
  plan.value.forEach(({ field, file }) => {
    forget(field);

    if (isHoloField(field)) {
      void readDataUrl(file).then((url) => {
        previews.set(field, url);
        publishPreviews();
      });

      return;
    }

    previews.set(field, URL.createObjectURL(file));
  });

  publishPreviews();

  return matched.map(({ item }) => item);
};

onBeforeUnmount(() => {
  Array.from(previews.keys()).forEach(forget);
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

  const fields = plan.value.flatMap(
    ({ field, file }): [FolderField, string][] => {
      const upload = files.find((candidate) => candidate.file === file);

      return upload?.blob ? [[field, upload.blob.signed_id]] : [];
    },
  );

  emit("mapped", Object.fromEntries(fields));
};

const isUploaded = (entry: PlannedFile) => uploaded.value.includes(entry.file);
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
      :filter="filterFolder"
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
        <li v-for="entry in plan" :key="entry.field">
          <span class="views-folder-upload__state">
            <i
              v-if="isUploaded(entry)"
              class="fa-duotone fa-circle-check text-success"
            />
            <i v-else class="fa-light fa-cloud-upload" />
          </span>
          <span class="views-folder-upload__field">
            <span class="views-folder-upload__label">
              {{ t(`labels.model.${entry.field}`) }}
            </span>
            <span class="views-folder-upload__filename">
              {{ entry.filename }}
            </span>
          </span>
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
