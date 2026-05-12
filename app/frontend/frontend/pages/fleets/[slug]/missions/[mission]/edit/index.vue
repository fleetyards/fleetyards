<script lang="ts">
export default {
  name: "FleetMissionEditBasicPage",
};
</script>

<script lang="ts" setup>
import { useForm, type SubmissionHandler } from "vee-validate";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import MissionEditFormShell from "@/frontend/components/Fleets/Missions/MissionEditFormShell/index.vue";
import {
  type Fleet,
  type FilterOption,
  type MissionExtended,
  type MissionUpdateInput,
  MissionCategory,
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
    },
    validationSchema,
  });

const [title, titleProps] = defineField("title");
const [category, categoryProps] = defineField("category");
const [scenario, scenarioProps] = defineField("scenario");

const { suggestions: scenarioSuggestions } = useMissionScenarios();

const categoryOptions = computed<FilterOption[]>(() =>
  Object.values(MissionCategory).map((value) => ({
    value,
    label: t(`labels.fleets.missions.categories.${value}`),
  })),
);

const wrapHandleSubmit = (cb: SubmissionHandler<MissionUpdateInput>) =>
  handleSubmit((values, ctx) =>
    cb(
      {
        title: values.title,
        category: values.category as never,
        scenario: values.scenario || null,
      },
      ctx,
    ),
  );
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.missions.editBasic") }}</Heading>
  <MissionEditFormShell
    :fleet="fleet"
    :mission="mission"
    :handle-submit="wrapHandleSubmit"
    :meta="meta"
    :set-errors="setErrors"
    form-id="fleet-mission-edit-basic"
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
        <FilterGroup
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
  </MissionEditFormShell>
</template>
