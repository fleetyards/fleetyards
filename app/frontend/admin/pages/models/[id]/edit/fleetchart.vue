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
  useReloadOneModelShipViews,
} from "@/services/fyAdminApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { type BaseFieldProps, useForm } from "vee-validate";
import { type Ref } from "vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import ModelForm from "@/admin/components/Models/Form/index.vue";
import ViewsFolderUpload from "@/admin/components/Models/ViewsFolderUpload/index.vue";
import {
  type FolderField,
  FIELD_ORDER,
  FIELD_SECTIONS,
} from "@/admin/components/Models/ViewsFolderUpload/mapping";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useModelMediaUpdates } from "@/admin/composables/useModelMediaUpdates";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayConfirm, displaySuccess } = useAppNotifications();

useModelMediaUpdates(() => props.model.id);

const isProcessing = (field: FolderField) =>
  props.model.mediaProcessing.includes(field);

const translationKey = (field: FolderField) =>
  field === "holo" ? "model.defaultHolo" : `model.${field}`;

const { defineField, handleSubmit, meta, setFieldValue } =
  useForm<ModelUpdateInput>({
    initialValues: Object.fromEntries(
      FIELD_ORDER.map((field) => [field, undefined]),
    ) as ModelUpdateInput,
  });

const definedFields = FIELD_ORDER.map(
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

const syncMutation = useReloadOneModelShipViews({
  mutation: {
    onSuccess: () => {
      displaySuccess({
        text: t("messages.model.syncShipViewsStarted"),
      });
    },
  },
});

const syncShipViews = () => {
  if (!props.model.id) return;

  displayConfirm({
    text: t("messages.confirm.model.syncShipViews"),
    onConfirm: async () => {
      await syncMutation.mutateAsync({ id: props.model.id! });
    },
  });
};

const onFolderMapped = (fields: Partial<Record<FolderField, string>>) => {
  Object.entries(fields).forEach(([field, signedId]) => {
    setFieldValue(field as FolderField, signedId);
  });
};
</script>

<template>
  <div class="flex items-center justify-between mb-4">
    <Heading hero>{{ t("headlines.admin.models.edit.fleetchart") }}</Heading>
    <Btn :loading="syncMutation.isPending.value" @click="syncShipViews">
      <i class="fa-duotone fa-cloud-arrow-down" />
      {{ t("actions.models.syncShipViews") }}
    </Btn>
  </div>
  <ModelForm :model="model" :handle-submit="handleSubmit" :meta="meta">
    <ViewsFolderUpload
      :processing="model.mediaProcessing"
      @selected="onFolderSelected"
      @mapped="onFolderMapped"
    />

    <section
      v-for="section in FIELD_SECTIONS"
      :key="section.state"
      class="fleetchart-section"
    >
      <Heading level="h2" size="lg">
        {{ t(`labels.model.state.${section.state}`) }}
      </Heading>

      <div class="row">
        <div
          v-for="field in section.holos"
          :key="field"
          class="col-12 col-sm-6 col-md-3"
        >
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

      <div v-for="(row, index) in section.views" :key="index" class="row">
        <div v-for="field in row" :key="field" class="col-12 col-sm-6 col-md-3">
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
    </section>
  </ModelForm>
</template>

<style lang="scss" scoped>
.fleetchart-section {
  margin-top: 2.5rem;
}
</style>
