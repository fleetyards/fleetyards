<script lang="ts">
export default {
  name: "FleetMissionsTeamModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type Mission,
  type MissionTeam,
  useCreateMissionTeam,
  useUpdateMissionTeam,
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

const { defineField, handleSubmit } = useForm({
  initialValues: {
    title: props.team?.title ?? "",
    description: props.team?.description ?? "",
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");

const createMutation = useCreateMissionTeam();
const updateMutation = useUpdateMissionTeam();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  const data = {
    title: values.title,
    description: values.description || undefined,
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
        data,
      });

  await mutation
    .then(() => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleets.missionTeam.update.success")
          : t("messages.fleets.missionTeam.create.success"),
      });
      comlink.emit("mission-children-changed");
      comlink.emit("close-modal");
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
      <FormInput
        v-model="title"
        v-bind="titleProps"
        name="title"
        :rules="validationSchema.title"
        :label="t('labels.fleets.missions.title')"
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.fleets.missions.description')"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
          @click="onSubmit"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
