<script lang="ts">
export default {
  name: "FleetMissionsMissionModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FilterOption,
  type Mission,
  type MissionExtended,
  MissionCategory,
  useCreateFleetMission,
  useUpdateFleetMission,
} from "@/services/fyApi";
import { useMissionScenarios } from "@/frontend/composables/useMissionScenarios";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  mission?: Mission | MissionExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const isEdit = computed(() => !!props.mission);
const submitting = ref(false);

const validationSchema = {
  title: "required|min:2",
};

const { defineField, handleSubmit } = useForm({
  initialValues: {
    title: props.mission?.title ?? "",
    description: props.mission?.description ?? "",
    category: props.mission?.category ?? MissionCategory.other,
    scenario:
      (props.mission as { scenario?: string | null } | undefined)?.scenario ??
      "",
    coverImage: undefined as string | undefined,
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [category, categoryProps] = defineField("category");
const [scenario, scenarioProps] = defineField("scenario");
const [coverImage, coverImageProps] = defineField("coverImage");

const { suggestions: scenarioSuggestions } = useMissionScenarios();

const categoryOptions = computed<FilterOption[]>(() =>
  Object.values(MissionCategory).map((value) => ({
    value,
    label: t(`labels.fleets.missions.categories.${value}`),
  })),
);

const existingCoverImage = computed(() => {
  return (
    props.mission as
      | { coverImage?: { url?: string; mediumUrl?: string } | null }
      | undefined
  )?.coverImage;
});

const createMutation = useCreateFleetMission();
const updateMutation = useUpdateFleetMission();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    title: values.title,
    description: values.description || undefined,
    category: values.category as never,
    scenario: values.scenario || null,
    coverImage: values.coverImage || undefined,
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        slug: props.mission!.slug,
        data,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        data,
      });

  await mutation
    .then((response) => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleets.mission.update.success")
          : t("messages.fleets.mission.create.success"),
      });
      comlink.emit(
        isEdit.value ? "fleet-mission-updated" : "fleet-mission-created",
      );
      comlink.emit("close-modal");

      if (!isEdit.value && response?.slug) {
        void router.push({
          name: "fleet-mission",
          params: { slug: props.fleet.slug, mission: response.slug },
        });
      }
    })
    .catch(() => {
      displayAlert({
        text: isEdit.value
          ? t("messages.fleets.mission.update.failure")
          : t("messages.fleets.mission.create.failure"),
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
        ? t('headlines.fleets.missions.edit')
        : t('headlines.fleets.missions.create')
    "
  >
    <form id="mission-form" @submit.prevent="onSubmit">
      <FormFileInput
        v-model="coverImage"
        v-bind="coverImageProps"
        :file="existingCoverImage as never"
        name="coverImage"
        :label="t('labels.fleets.missions.coverImage')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
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
      <FilterGroup
        v-model="category"
        v-bind="categoryProps"
        :options="categoryOptions"
        :label="t('labels.fleets.missions.category')"
        name="category"
        :searchable="false"
      />
      <FormInput
        v-model="scenario"
        v-bind="scenarioProps"
        name="scenario"
        :label="t('labels.fleets.missions.scenario')"
        list="mission-scenario-suggestions"
        autocomplete="off"
      />
      <datalist id="mission-scenario-suggestions">
        <option
          v-for="suggestion in scenarioSuggestions"
          :key="suggestion"
          :value="suggestion"
        />
      </datalist>
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
