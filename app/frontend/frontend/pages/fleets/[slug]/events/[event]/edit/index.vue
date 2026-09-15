<script lang="ts">
export default {
  name: "FleetEventEditDetailsPage",
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
import EventEditFormShell from "@/frontend/components/Fleets/Events/EventEditFormShell/index.vue";
import {
  type Fleet,
  type FilterOption,
  type FleetEventExtended,
  type FleetEventUpdateInput,
  MissionCategoryEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionScenarios } from "@/frontend/composables/useMissionScenarios";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const validationSchema = {
  title: "required|min:2",
};

const { defineField, handleSubmit, meta, setErrors } =
  useForm<FleetEventUpdateInput>({
    initialValues: {
      title: props.event.title,
      category: props.event.category,
      scenario: props.event.scenario ?? "",
      description: props.event.description ?? "",
      briefing: props.event.briefing ?? "",
      coverImage: undefined,
      coverImagePreset: props.event.coverImagePreset ?? null,
    },
    validationSchema,
  });

const [title, titleProps] = defineField("title");
const [category, categoryProps] = defineField("category");
const [scenario, scenarioProps] = defineField("scenario");
const [description, descriptionProps] = defineField("description");
const [briefing, briefingProps] = defineField("briefing");
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
      props.event as
        { coverImage?: { url?: string; mediumUrl?: string } | null } | undefined
    )?.coverImage,
);

const wrapHandleSubmit = (cb: SubmissionHandler<FleetEventUpdateInput>) =>
  handleSubmit((values, ctx) =>
    cb(
      {
        ...values,
        scenario: values.scenario || null,
        // `null`, not `undefined`: an empty textarea is an instruction to clear
        // the field, and a dropped key leaves the stored text in place.
        description: values.description || null,
        briefing: values.briefing || null,
        // Passed through rather than coerced: `undefined` drops the key and
        // keeps what is attached, `null` is how the field says it was cleared,
        // and a signed id is a replacement. `|| undefined` turned a clear back
        // into a keep, so the picture could not be removed.
        coverImage: values.coverImage,
        // The field keeps the two exclusive itself -- an upload retires the
        // preset, a preset clears the upload -- so this is passed on as it
        // stands rather than coerced a second time.
        coverImagePreset: values.coverImagePreset,
      } as never,
      ctx,
    ),
  );
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.events.editDetails") }}</Heading>
  <EventEditFormShell
    :fleet="fleet"
    :event="event"
    :handle-submit="wrapHandleSubmit"
    :meta="meta"
    :set-errors="setErrors"
    form-id="fleet-event-edit-details"
  >
    <div class="row">
      <div class="col-12">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          name="title"
          :rules="validationSchema.title"
          :label="t('labels.fleets.events.title')"
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
    </div>

    <div class="row">
      <div class="col-12">
        <FormInput
          v-model="scenario"
          v-bind="scenarioProps"
          name="scenario"
          :label="t('labels.fleets.missions.scenario')"
          list="event-edit-scenario-suggestions"
          autocomplete="off"
        />
        <datalist id="event-edit-scenario-suggestions">
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
          :label="t('labels.fleets.events.description')"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <FormTextarea
          v-model="briefing"
          v-bind="briefingProps"
          name="briefing"
          :label="t('labels.fleets.events.briefing')"
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
  </EventEditFormShell>
</template>
