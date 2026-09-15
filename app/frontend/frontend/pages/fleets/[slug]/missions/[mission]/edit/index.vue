<script lang="ts">
export default {
  name: "FleetMissionEditDetailsPage",
};
</script>

<script lang="ts" setup>
import { useForm, type SubmissionHandler } from "vee-validate";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import MissionEditFormShell from "@/frontend/components/Fleets/Missions/MissionEditFormShell/index.vue";
import {
  type Fleet,
  type FilterOption,
  type MissionExtended,
  type MissionUpdateInput,
  MissionCategoryEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionScenarios } from "@/frontend/composables/useMissionScenarios";

type Props = {
  fleet: Fleet;
  mission: MissionExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const validationSchema = {
  title: "required|min:2",
};

const { defineField, handleSubmit, meta, setErrors } =
  useForm<MissionUpdateInput>({
    initialValues: {
      title: props.mission.title,
      category: props.mission.category,
      scenario: props.mission.scenario ?? "",
      description: props.mission.description ?? "",
      coverImage: undefined,
      coverImagePreset: props.mission.coverImagePreset ?? null,
    },
    validationSchema,
  });

const [title, titleProps] = defineField("title");
const [category, categoryProps] = defineField("category");
const [scenario, scenarioProps] = defineField("scenario");
const [description, descriptionProps] = defineField("description");
const [coverImage, coverImageProps] = defineField("coverImage");
const [coverImagePreset] = defineField("coverImagePreset");

const { suggestions: scenarioSuggestions } = useMissionScenarios();

const categoryOptions = computed<FilterOption[]>(() =>
  Object.values(MissionCategoryEnum).map((value) => ({
    value,
    label: t(`labels.fleets.missions.categories.${value}`),
  })),
);

const existingCoverImage = computed(
  () =>
    (
      props.mission as
        { coverImage?: { url?: string; mediumUrl?: string } | null } | undefined
    )?.coverImage,
);

const wrapHandleSubmit = (cb: SubmissionHandler<MissionUpdateInput>) =>
  handleSubmit((values, ctx) =>
    cb(
      {
        title: values.title,
        category: values.category as never,
        scenario: values.scenario || null,
        description: values.description || null,
        // Passed through rather than coerced: `undefined` drops the key and
        // keeps what is attached, `null` is how the field says it was cleared,
        // and a signed id is a replacement. `|| undefined` turned a clear back
        // into a keep, so the picture could not be removed.
        coverImage: values.coverImage,
        // The field keeps the two exclusive itself -- an upload retires the
        // preset, a preset clears the upload -- so this is passed on as it
        // stands rather than coerced a second time.
        coverImagePreset: values.coverImagePreset,
      },
      ctx,
    ),
  );
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.missions.editDetails") }}</Heading>
  <MissionEditFormShell
    :fleet="fleet"
    :mission="mission"
    :handle-submit="wrapHandleSubmit"
    :meta="meta"
    :set-errors="setErrors"
    form-id="fleet-mission-edit-details"
  >
    <div class="row">
      <div class="col-12">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          name="title"
          :rules="validationSchema.title"
          :label="t('labels.fleets.missions.title')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="category"
          v-bind="categoryProps"
          :options="categoryOptions"
          :label="t('labels.fleets.missions.category')"
          name="category"
          :searchable="false"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="scenario"
          v-bind="scenarioProps"
          name="scenario"
          :label="t('labels.fleets.missions.scenario')"
          list="mission-edit-scenario-suggestions"
          autocomplete="off"
        />
        <datalist id="mission-edit-scenario-suggestions">
          <option
            v-for="suggestion in scenarioSuggestions"
            :key="suggestion"
            :value="suggestion"
          />
        </datalist>
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
          :label="t('labels.fleets.missions.description')"
        />
      </div>
    </div>

    <div class="row">
      <div class="col-12">
        <!-- The picker opens on the category this form is editing, not on the
             saved one: the art follows the field. -->
        <FormFileInput
          v-model="coverImage"
          v-model:preset-value="coverImagePreset"
          v-bind="coverImageProps"
          :file="existingCoverImage as never"
          name="coverImage"
          :label="t('labels.fleets.missions.coverImage')"
          :allowed-types="AllowedFileTypes.IMAGE"
          preset-catalogue="missions"
          :preset-group="category as string"
          clearable
        />
      </div>
    </div>
  </MissionEditFormShell>
</template>
