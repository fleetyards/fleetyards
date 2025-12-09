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
  newTopView: undefined,
  newSideView: undefined,
  newFrontView: undefined,
  newAngledView: undefined,
  newTopViewColored: undefined,
  newSideViewColored: undefined,
  newFrontViewColored: undefined,
  newAngledViewColored: undefined,
});

const { defineField } = useForm<ModelUpdateInput>({
  initialValues: initialValues.value,
});

const [newTopView, newTopViewProps] = defineField("newTopView");
const [newSideView, newSideViewProps] = defineField("newSideView");
const [newFrontView, newFrontViewProps] = defineField("newFrontView");
const [newAngledView, newAngledViewProps] = defineField("newAngledView");
const [newTopViewColored, newTopViewColoredProps] =
  defineField("newTopViewColored");
const [newSideViewColored, newSideViewColoredProps] =
  defineField("newSideViewColored");
const [newFrontViewColored, newFrontViewColoredProps] = defineField(
  "newFrontViewColored",
);
const [newAngledViewColored, newAngledViewColoredProps] = defineField(
  "newAngledViewColored",
);
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.fleetchart") }}</Heading>
  <ModelForm :model="model" :initial-values="initialValues">
    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newTopView"
          :file="model.media.topView"
          translation-key="model.topView"
          v-bind="newTopViewProps"
          :allowed-types="AllowedFileTypes.IMAGE"
          name="newTopView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newSideView"
          :file="model.media.sideView"
          translation-key="model.sideView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="newSideViewProps"
          name="newSideView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newFrontView"
          :file="model.media.frontView"
          translation-key="model.frontView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="newFrontViewProps"
          name="newFrontView"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newAngledView"
          :file="model.media.angledView"
          translation-key="model.angledView"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="newAngledViewProps"
          name="newAngledView"
          transparent
          clearable
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newTopViewColored"
          :file="model.media.topViewColored"
          translation-key="model.topViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="newTopViewColoredProps"
          name="newTopViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newSideViewColored"
          :file="model.media.sideViewColored"
          translation-key="model.sideViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="newSideViewColoredProps"
          name="newSideViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newFrontViewColored"
          :file="model.media.frontViewColored"
          translation-key="model.frontViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="newFrontViewColoredProps"
          name="newFrontViewColored"
          transparent
          clearable
        />
      </div>
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="newAngledViewColored"
          :file="model.media.angledViewColored"
          translation-key="model.angledViewColored"
          :allowed-types="AllowedFileTypes.IMAGE"
          v-bind="newAngledViewColoredProps"
          name="newAngledViewColored"
          transparent
          clearable
        />
      </div>
    </div>
  </ModelForm>
</template>
