<script lang="ts">
export default {
  name: "AdminModelEditFleetchartPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import { type BaseFieldProps, useForm } from "vee-validate";
import { type Ref } from "vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import ModelForm from "@/admin/components/Models/Form/index.vue";
import ViewsFolderUpload from "@/admin/components/Models/ViewsFolderUpload/index.vue";
import {
  type FolderField,
  type HoloField,
  type ViewField,
  HOLO_FIELDS,
  VIEW_FIELDS,
} from "@/admin/components/Models/ViewsFolderUpload/mapping";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useModelMediaUpdates } from "@/admin/composables/useModelMediaUpdates";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

useModelMediaUpdates(() => props.model.id);

const isProcessing = (field: FolderField) =>
  props.model.mediaProcessing.includes(field);

const FIELDS: readonly FolderField[] = [...HOLO_FIELDS, ...VIEW_FIELDS];

const HOLO_ROWS: HoloField[][] = [
  ["holo", "extendedHolo", "landedHolo"],
  ["holoLite", "extendedHoloLite", "landedHoloLite"],
  ["holoTextured"],
];

const viewRow = (
  prefix: "" | "extended" | "landed",
  viewpoints: string[],
  colored: boolean,
) =>
  viewpoints.map((viewpoint) => {
    const view = prefix
      ? `${prefix}${viewpoint.charAt(0).toUpperCase()}${viewpoint.slice(1)}View`
      : `${viewpoint}View`;

    return (colored ? `${view}Colored` : view) as ViewField;
  });

// One block per state: the four views from the front, then the four from
// behind and below, each plain and then coloured.
const VIEW_BLOCKS: ViewField[][][] = (["", "extended", "landed"] as const).map(
  (prefix) =>
    [
      ["top", "side", "front", "angled"],
      ["bottom", "starboard", "rear", "angledRear"],
    ].flatMap((viewpoints) => [
      viewRow(prefix, viewpoints, false),
      viewRow(prefix, viewpoints, true),
    ]),
);

const translationKey = (field: FolderField) =>
  field === "holo" ? "model.defaultHolo" : `model.${field}`;

const { defineField, handleSubmit, meta, setFieldValue } =
  useForm<ModelUpdateInput>({
    initialValues: Object.fromEntries(
      FIELDS.map((field) => [field, undefined]),
    ) as ModelUpdateInput,
  });

const definedFields = FIELDS.map(
  (field) => [field, defineField(field)] as const,
);

// `reactive` unwraps the refs, so `v-model="values[field]"` writes through to
// the form.
const values = reactive(
  Object.fromEntries(
    definedFields.map(([field, [value]]) => [field, value]),
  ) as Record<FolderField, Ref<string | null | undefined>>,
);

const fieldProps = reactive(
  Object.fromEntries(
    definedFields.map(([field, [, attributes]]) => [field, attributes]),
  ) as Record<FolderField, Ref<BaseFieldProps>>,
);

// Kept for as long as the page lives. A save refetches the model, but the trim
// that follows replaces the blob and purges the one that refetch named, so the
// local file is the picture that stays true.
const previews = ref<Partial<Record<FolderField, string>>>({});

const onFolderSelected = (fields: Partial<Record<FolderField, string>>) => {
  previews.value = fields;
};

const onFolderMapped = (fields: Partial<Record<FolderField, string>>) => {
  Object.entries(fields).forEach(([field, signedId]) => {
    setFieldValue(field as FolderField, signedId);
  });
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.fleetchart") }}</Heading>
  <ModelForm :model="model" :handle-submit="handleSubmit" :meta="meta">
    <ViewsFolderUpload
      :processing="model.mediaProcessing"
      @selected="onFolderSelected"
      @mapped="onFolderMapped"
    />

    <hr />

    <div v-for="(row, index) in HOLO_ROWS" :key="index" class="row">
      <div v-for="field in row" :key="field" class="col-12 col-md-4">
        <FormFileInput
          v-model="values[field]"
          :file="model.media[field]"
          :translation-key="translationKey(field)"
          v-bind="fieldProps[field]"
          :name="field"
          :preview-src="previews[field]"
          :allowed-types="AllowedFileTypes.HOLO"
          clearable
        />
      </div>
    </div>

    <template v-for="(block, blockIndex) in VIEW_BLOCKS" :key="blockIndex">
      <hr />

      <div v-for="(row, rowIndex) in block" :key="rowIndex" class="row">
        <div v-for="field in row" :key="field" class="col-12 col-md-4">
          <FormFileInput
            v-model="values[field]"
            :file="model.media[field]"
            :translation-key="translationKey(field)"
            v-bind="fieldProps[field]"
            :allowed-types="AllowedFileTypes.IMAGE"
            :name="field"
            :processing="isProcessing(field)"
            :preview-src="previews[field]"
            transparent
            clearable
          />
        </div>
      </div>
    </template>
  </ModelForm>
</template>
