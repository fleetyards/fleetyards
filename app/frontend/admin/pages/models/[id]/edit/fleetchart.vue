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
import { useForm } from "vee-validate";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import ModelForm from "@/admin/components/Models/Form/index.vue";
import ViewsFolderUpload from "@/admin/components/Models/ViewsFolderUpload/index.vue";
import {
  type FolderField,
  type ViewField,
} from "@/admin/components/Models/ViewsFolderUpload/mapping";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";

type Props = {
  model: ModelExtended;
};

defineProps<Props>();

const { t } = useI18n();

const initialValues = ref<ModelUpdateInput>({
  holo: undefined,
  extendedHolo: undefined,
  topView: undefined,
  sideView: undefined,
  frontView: undefined,
  angledView: undefined,
  topViewColored: undefined,
  sideViewColored: undefined,
  frontViewColored: undefined,
  angledViewColored: undefined,
  extendedTopView: undefined,
  extendedSideView: undefined,
  extendedFrontView: undefined,
  extendedAngledView: undefined,
  extendedTopViewColored: undefined,
  extendedSideViewColored: undefined,
  extendedFrontViewColored: undefined,
  extendedAngledViewColored: undefined,
});

const { defineField, handleSubmit, meta, setFieldValue } =
  useForm<ModelUpdateInput>({
    initialValues: initialValues.value,
  });

// Kept for as long as the page lives. A save refetches the model, but the trim
// that follows replaces the blob and purges the one that refetch named, so the
// local file is the picture that stays true.
const previews = ref<Partial<Record<ViewField, string>>>({});

const onFolderSelected = (views: Partial<Record<ViewField, string>>) => {
  previews.value = views;
};

const onFolderMapped = (fields: Partial<Record<FolderField, string>>) => {
  Object.entries(fields).forEach(([field, signedId]) => {
    setFieldValue(field as FolderField, signedId);
  });
};

const [holo, holoProps] = defineField("holo");
const [extendedHolo, extendedHoloProps] = defineField("extendedHolo");
const [topView, topViewProps] = defineField("topView");
const [sideView, sideViewProps] = defineField("sideView");
const [frontView, frontViewProps] = defineField("frontView");
const [angledView, angledViewProps] = defineField("angledView");
const [topViewColored, topViewColoredProps] = defineField("topViewColored");
const [sideViewColored, sideViewColoredProps] = defineField("sideViewColored");
const [frontViewColored, frontViewColoredProps] =
  defineField("frontViewColored");
const [angledViewColored, angledViewColoredProps] =
  defineField("angledViewColored");
const [extendedTopView, extendedTopViewProps] = defineField("extendedTopView");
const [extendedSideView, extendedSideViewProps] =
  defineField("extendedSideView");
const [extendedFrontView, extendedFrontViewProps] =
  defineField("extendedFrontView");
const [extendedAngledView, extendedAngledViewProps] =
  defineField("extendedAngledView");
const [extendedTopViewColored, extendedTopViewColoredProps] = defineField(
  "extendedTopViewColored",
);
const [extendedSideViewColored, extendedSideViewColoredProps] = defineField(
  "extendedSideViewColored",
);
const [extendedFrontViewColored, extendedFrontViewColoredProps] = defineField(
  "extendedFrontViewColored",
);
const [extendedAngledViewColored, extendedAngledViewColoredProps] = defineField(
  "extendedAngledViewColored",
);
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.fleetchart") }}</Heading>
  <ModelForm :model="model" :handle-submit="handleSubmit" :meta="meta">
    <ViewsFolderUpload @selected="onFolderSelected" @mapped="onFolderMapped" />

    <hr />

    <div class="row">
      <div class="col-12 col-md-6">
        <FormFileInput
          v-model="holo"
          :file="model.media.holo"
          translation-key="model.defaultHolo"
          v-bind="holoProps"
          name="holo"
          :allowed-types="AllowedFileTypes.HOLO"
          clearable
        />
      </div>
      <div class="col-12 col-md-6">
        <FormFileInput
          v-model="extendedHolo"
          :file="model.media.extendedHolo"
          translation-key="model.extendedHolo"
          v-bind="extendedHoloProps"
          name="extendedHolo"
          :allowed-types="AllowedFileTypes.HOLO"
          clearable
        />
      </div>
    </div>

    <hr />

    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="topView"
          :file="model.media.topView"
          translation-key="model.topView"
          v-bind="topViewProps"
          :allowed-types="AllowedFileTypes.IMAGE"
          name="topView"
          :preview-src="previews.topView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="sideView"
          :file="model.media.sideView"
          translation-key="model.sideView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="sideViewProps"
          name="sideView"
          :preview-src="previews.sideView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="frontView"
          :file="model.media.frontView"
          translation-key="model.frontView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="frontViewProps"
          name="frontView"
          :preview-src="previews.frontView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="angledView"
          :file="model.media.angledView"
          translation-key="model.angledView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="angledViewProps"
          name="angledView"
          :preview-src="previews.angledView"
          transparent
          clearable
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="topViewColored"
          :file="model.media.topViewColored"
          translation-key="model.topViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="topViewColoredProps"
          name="topViewColored"
          :preview-src="previews.topViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="sideViewColored"
          :file="model.media.sideViewColored"
          translation-key="model.sideViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="sideViewColoredProps"
          name="sideViewColored"
          :preview-src="previews.sideViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="frontViewColored"
          :file="model.media.frontViewColored"
          translation-key="model.frontViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="frontViewColoredProps"
          name="frontViewColored"
          :preview-src="previews.frontViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="angledViewColored"
          :file="model.media.angledViewColored"
          translation-key="model.angledViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="angledViewColoredProps"
          name="angledViewColored"
          :preview-src="previews.angledViewColored"
          transparent
          clearable
        />
      </div>
    </div>

    <hr />

    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedTopView"
          :file="model.media.extendedTopView"
          translation-key="model.extendedTopView"
          v-bind="extendedTopViewProps"
          :allowed-types="AllowedFileTypes.IMAGE"
          name="extendedTopView"
          :preview-src="previews.extendedTopView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedSideView"
          :file="model.media.extendedSideView"
          translation-key="model.extendedSideView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="extendedSideViewProps"
          name="extendedSideView"
          :preview-src="previews.extendedSideView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedFrontView"
          :file="model.media.extendedFrontView"
          translation-key="model.extendedFrontView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="extendedFrontViewProps"
          name="extendedFrontView"
          :preview-src="previews.extendedFrontView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedAngledView"
          :file="model.media.extendedAngledView"
          translation-key="model.extendedAngledView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="extendedAngledViewProps"
          name="extendedAngledView"
          :preview-src="previews.extendedAngledView"
          transparent
          clearable
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedTopViewColored"
          :file="model.media.extendedTopViewColored"
          translation-key="model.extendedTopViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="extendedTopViewColoredProps"
          name="extendedTopViewColored"
          :preview-src="previews.extendedTopViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedSideViewColored"
          :file="model.media.extendedSideViewColored"
          translation-key="model.extendedSideViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="extendedSideViewColoredProps"
          name="extendedSideViewColored"
          :preview-src="previews.extendedSideViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedFrontViewColored"
          :file="model.media.extendedFrontViewColored"
          translation-key="model.extendedFrontViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="extendedFrontViewColoredProps"
          name="extendedFrontViewColored"
          :preview-src="previews.extendedFrontViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="extendedAngledViewColored"
          :file="model.media.extendedAngledViewColored"
          translation-key="model.extendedAngledViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="extendedAngledViewColoredProps"
          name="extendedAngledViewColored"
          :preview-src="previews.extendedAngledViewColored"
          transparent
          clearable
        />
      </div>
    </div>
  </ModelForm>
</template>
