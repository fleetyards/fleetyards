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
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";

type Props = {
  model: ModelExtended;
};

defineProps<Props>();

const { t } = useI18n();

const initialValues = ref<ModelUpdateInput>({
  topView: undefined,
  sideView: undefined,
  frontView: undefined,
  angledView: undefined,
  topViewColored: undefined,
  sideViewColored: undefined,
  frontViewColored: undefined,
  angledViewColored: undefined,
});

const { defineField, handleSubmit, meta } = useForm<ModelUpdateInput>({
  initialValues: initialValues.value,
});

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
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.fleetchart") }}</Heading>
  <ModelForm :model="model" :handle-submit="handleSubmit" :meta="meta">
    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="topView"
          :file="model.media.topView"
          translation-key="model.topView"
          v-bind="topViewProps"
          :allowed-types="AllowedFileTypes.IMAGE"
          name="topView"
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
          transparent
          clearable
        />
      </div>
    </div>
  </ModelForm>
</template>
