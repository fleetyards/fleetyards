<script lang="ts">
export default {
  name: "FleetMissionsTeamModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormMarkdownEditor from "@/shared/components/base/FormMarkdownEditor/index.vue";
import SquadronSourceSelect from "@/frontend/components/Fleets/Squadrons/SquadronSourceSelect/index.vue";
import FlightSourceSelect from "@/frontend/components/Fleets/Squadrons/FlightSourceSelect/index.vue";
import { useSquadronTakeover } from "@/frontend/components/Fleets/Squadrons/SquadronSourceSelect/useSquadronTakeover";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import {
  type Fleet,
  type Mission,
  type MissionTeam,
  useCreateMissionTeam,
  useUpdateMissionTeam,
  type FleetSquadron,
  type FleetSquadronFlight,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  mission: Mission;
  team?: MissionTeam;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const isEdit = computed(() => !!props.team);
const submitting = ref(false);

const validationSchema = {
  title: "required|min:2",
};

const initialValues = {
  title: props.team?.title ?? "",
  description: props.team?.description ?? "",
  fleetSquadronId: props.team?.fleetSquadron?.id ?? null,
  sourceFlightId: null as string | null,
};

const { defineField, handleSubmit, values } = useForm({
  initialValues,
});

useModalDirty(useFormDirty(values, initialValues));

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [fleetSquadronId] = defineField("fleetSquadronId");
const [sourceFlightId] = defineField("sourceFlightId");

const takeOverSquadron = useSquadronTakeover(title, description);

const pickedSquadron = ref<FleetSquadron>();

const onPickSquadron = (squadron: FleetSquadron, previous?: FleetSquadron) => {
  takeOverSquadron(squadron, previous);
  pickedSquadron.value = squadron;
};

// A flight names the team over what is empty or still another pick's.
const takeOverFlight = (
  flight: FleetSquadronFlight,
  previous?: FleetSquadronFlight,
) => {
  if (
    !title.value ||
    title.value === previous?.name ||
    title.value === pickedSquadron.value?.name
  ) {
    title.value = flight.name;
  }

  if (
    !description.value ||
    description.value === (previous?.description ?? "") ||
    description.value === (pickedSquadron.value?.shortDescription ?? "")
  ) {
    description.value = flight.description ?? "";
  }
};

const createMutation = useCreateMissionTeam();
const updateMutation = useUpdateMissionTeam();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  const data = {
    title: values.title,
    description: values.description || null,
    fleetSquadronId: values.fleetSquadronId || null,
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        missionSlug: props.mission.slug,
        id: props.team!.id,
        data,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        missionSlug: props.mission.slug,
        data: { ...data, sourceFlightId: values.sourceFlightId || null },
      });

  await mutation
    .then(() => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleets.missionTeam.update.success")
          : t("messages.fleets.missionTeam.create.success"),
      });
      comlink.emit("mission-children-changed");
      comlink.emit("close-modal", true);
    })
    .catch(() => {
      displayAlert({
        text: isEdit.value
          ? t("messages.fleets.missionTeam.update.failure")
          : t("messages.fleets.missionTeam.create.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal
    :title="
      isEdit
        ? t('headlines.fleets.missions.editTeam')
        : t('headlines.fleets.missions.addTeam')
    "
  >
    <form id="team-form" @submit.prevent="onSubmit">
      <SquadronSourceSelect
        v-model="fleetSquadronId"
        :fleet="fleet"
        @pick="onPickSquadron"
      />
      <FlightSourceSelect
        v-if="!isEdit"
        v-model="sourceFlightId"
        :fleet="fleet"
        :squadron-id="fleetSquadronId"
        @pick="takeOverFlight"
      />
      <FormInput
        v-model="title"
        v-bind="titleProps"
        name="title"
        :rules="validationSchema.title"
        :label="t('labels.fleets.missions.title')"
      />
      <FormMarkdownEditor
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.fleets.missions.description')"
      />
    </form>

    <template #footer>
      <Btn :type="BtnTypesEnum.SUBMIT" form="team-form" :loading="submitting">
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
