<script lang="ts">
export default {
  name: "FleetMissionsForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import TeamCard from "@/frontend/components/Fleets/Missions/TeamCard/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FilterOption,
  type Mission,
  type MissionExtended,
  type MissionTeam,
  MissionCategory,
  useCreateFleetMission,
  useUpdateFleetMission,
  useSortMissionTeams,
} from "@/services/fyApi";
import { useMissionScenarios } from "@/frontend/composables/useMissionScenarios";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { useRouter } from "vue-router";
import Sortable from "sortablejs";

type Props = {
  fleet: Fleet;
  mission?: Mission | MissionExtended;
};

const props = defineProps<Props>();
const emit = defineEmits<{
  cancel: [];
}>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const isEdit = computed(() => !!props.mission);
const submitting = ref(false);

const validationSchema = {
  title: "required|min:2",
};

const { defineField, handleSubmit, meta } = useForm({
  initialValues: {
    title: props.mission?.title ?? "",
    description: props.mission?.description ?? "",
    category: props.mission?.category ?? MissionCategory.other,
    scenario:
      (props.mission as { scenario?: string | null } | undefined)?.scenario ??
      "",
    coverImage: undefined as string | undefined,
    coverImagePreset:
      (props.mission as { coverImagePreset?: string | null } | undefined)
        ?.coverImagePreset ?? null,
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [category, categoryProps] = defineField("category");
const [scenario, scenarioProps] = defineField("scenario");
const [coverImage, coverImageProps] = defineField("coverImage");
const [coverImagePreset] = defineField("coverImagePreset");

const { suggestions: scenarioSuggestions } = useMissionScenarios();
const { presetsFor } = useMissionCover();

const presetOptions = computed(() => presetsFor(category.value as string));

const selectPreset = (key: string) => {
  coverImagePreset.value = coverImagePreset.value === key ? null : key;
};

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

const teams = ref<MissionTeam[]>([]);
const teamsContainer = ref<HTMLElement | null>(null);
let teamsSortable: Sortable | null = null;
const sortTeamsMutation = useSortMissionTeams();

watch(
  () => props.mission,
  (newMission) => {
    if (newMission && "teams" in newMission) {
      teams.value = [...(newMission as MissionExtended).teams];
    } else {
      teams.value = [];
    }
  },
  { immediate: true },
);

const initTeamsSortable = () => {
  teamsSortable?.destroy();
  if (!teamsContainer.value || !isEdit.value) return;

  teamsSortable = Sortable.create(teamsContainer.value, {
    animation: 150,
    handle: ".team-drag-handle",
    onEnd: () => {
      const items = teamsContainer.value?.querySelectorAll("[data-team-id]");
      if (!items) return;
      const order = Array.from(items)
        .map((el) => el.getAttribute("data-team-id"))
        .filter(Boolean) as string[];

      teams.value = order
        .map((id) => teams.value.find((team) => team.id === id))
        .filter(Boolean) as MissionTeam[];

      if (!props.mission) return;
      void sortTeamsMutation
        .mutateAsync({
          fleetSlug: props.fleet.slug,
          missionSlug: props.mission.slug,
          data: { sorting: order },
        })
        .catch(() =>
          displayAlert({
            text: t("messages.fleets.missionTeam.update.failure"),
          }),
        );
    },
  });
};

watch([teams, isEdit], () => {
  void nextTick(() => initTeamsSortable());
});

onUnmounted(() => {
  teamsSortable?.destroy();
});

const openAddTeamModal = () => {
  if (!props.mission) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Missions/TeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      mission: props.mission,
    },
  });
};

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    title: values.title,
    description: values.description || undefined,
    category: values.category as never,
    scenario: values.scenario || null,
    coverImagePreset: values.coverImage ? null : values.coverImagePreset,
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

      const targetSlug = isEdit.value ? props.mission!.slug : response?.slug;
      if (targetSlug) {
        void router.push({
          name: "fleet-mission",
          params: { slug: props.fleet.slug, mission: targetSlug },
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
  <form id="mission-form" class="mission-form" @submit.prevent="onSubmit">
    <FormTabs>
      <FormTab
        id="basic"
        :label="t('labels.fleets.events.tabs.basic')"
        :fields="['title']"
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
          </div>
        </div>
      </FormTab>

      <FormTab
        id="description"
        :label="t('labels.fleets.events.tabs.description')"
      >
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

        <div v-if="presetOptions.length" class="row">
          <div class="col-12">
            <span class="cover-presets-label">
              {{ t("labels.fleets.missions.coverPresets") }}
            </span>
            <div class="cover-presets-grid">
              <button
                v-for="preset in presetOptions"
                :key="preset.key"
                type="button"
                class="cover-preset"
                :class="{
                  'cover-preset--active': coverImagePreset === preset.key,
                }"
                :style="{ backgroundImage: `url(${preset.url})` }"
                @click="selectPreset(preset.key)"
              />
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <FormFileInput
              v-model="coverImage"
              v-bind="coverImageProps"
              :file="existingCoverImage as never"
              name="coverImage"
              :label="t('labels.fleets.missions.coverImage')"
              :allowed-types="AllowedFileTypes.IMAGE"
              clearable
            />
          </div>
        </div>
      </FormTab>

      <FormTab
        id="teams"
        :label="t('labels.fleets.events.tabs.teams')"
        :hidden="!isEdit"
      >
        <div class="teams-section__header">
          <Btn :inline="true" size="small" @click="openAddTeamModal">
            <i class="fa-light fa-plus" />
            <span>{{ t("actions.fleets.missions.addTeam") }}</span>
          </Btn>
        </div>
        <div ref="teamsContainer" class="mission-teams">
          <TeamCard
            v-for="team in teams"
            :key="team.id"
            :data-team-id="team.id"
            :team="team"
            :fleet="fleet"
            :mission="mission!"
            editable
          />
        </div>
        <p v-if="!teams.length" class="text-muted">
          {{ t("labels.fleets.missions.noTeams") }}
        </p>
      </FormTab>

      <FormActions
        :submitting="submitting"
        form-id="mission-form"
        :dirty="meta.dirty || meta.touched"
        @cancel="emit('cancel')"
      />
    </FormTabs>
  </form>
</template>

<style lang="scss" scoped>
.mission-form {
  width: 100%;
}
.cover-presets-label {
  display: block;
  margin-bottom: 0.4rem;
  font-size: 0.85rem;
  color: var(--text-muted);
}
.cover-presets-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}
.cover-preset {
  position: relative;
  height: 70px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  border: 2px solid transparent;
  border-radius: 4px;
  cursor: pointer;
  padding: 0;
  transition:
    border-color 0.15s,
    transform 0.1s;

  &:hover {
    border-color: rgba(255, 255, 255, 0.3);
    transform: scale(1.02);
  }
}
.cover-preset--active {
  border-color: var(--accent, #4aa);
  box-shadow: 0 0 0 1px var(--accent, #4aa);
}
.teams-section__header {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 0.75rem;
}
.mission-teams {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
