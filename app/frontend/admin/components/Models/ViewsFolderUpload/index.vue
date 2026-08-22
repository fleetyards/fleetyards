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
  isViewField,
  mapFolderFiles,
  type FolderField,
  type MappedFile,
  type ViewField,
} from "@/admin/components/Models/ViewsFolderUpload/mapping";

type PlannedFile = MappedFile & { file: File };

const { t } = useI18n();

const emit = defineEmits<{
  selected: [previews: Partial<Record<ViewField, string>>];
  mapped: [fields: Partial<Record<FolderField, string>>];
}>();

const plan = ref<PlannedFile[]>([]);
const ignored = ref<string[]>([]);
const uploaded = ref<File[]>([]);
const uploading = ref(false);
const previews = new Map<ViewField, string>();

// The file input reports the folder in webkitRelativePath, a drop does not.
const nameOf = (file: File) => file.webkitRelativePath || file.name;

const basename = (filename: string) => filename.split("/").pop() || filename;

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

  // A signed id only arrives once the upload finishes, but a picture can be
  // shown from the local file at once, so no input sits there empty meanwhile.
  // A holo has no still to show, and is left to its own viewer.
  plan.value.forEach(({ field, file }) => {
    if (!isViewField(field)) {
      return;
    }

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
