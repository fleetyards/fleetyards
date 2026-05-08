<script lang="ts">
export default {
  name: "FleetEventsForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FilterOption,
  type FleetEvent,
  type FleetEventTeam,
  type Mission,
  type MissionExtended,
  FleetEventVisibility,
  MissionCategory,
  useCreateFleetEvent,
  useUpdateFleetEvent,
} from "@/services/fyApi";
import EventTeamCard from "@/frontend/components/Fleets/Events/EventTeamCard/index.vue";
import { useMissionScenarios } from "@/frontend/composables/useMissionScenarios";
import { useMissionCover } from "@/frontend/composables/useMissionCover";
import { TIMEZONE_OPTIONS } from "@/shared/utils/Timezones";
import { useRouter } from "vue-router";
import { format, parseISO } from "date-fns";

type Props = {
  fleet: Fleet;
  event?: FleetEvent;
  mission?: Mission | MissionExtended;
  startsAtPrefill?: string;
};

const props = defineProps<Props>();
const emit = defineEmits<{
  cancel: [];
}>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const isEdit = computed(() => !!props.event);
const submitting = ref(false);

const validationSchema = {
  title: "required|min:2",
  startsAt: "required",
  timezone: "required",
};

const LOCAL_FORMAT = "yyyy-MM-dd'T'HH:mm";

const toLocal = (iso: string | null | undefined) => {
  if (!iso) return "";
  try {
    return format(parseISO(iso), LOCAL_FORMAT);
  } catch {
    return "";
  }
};

const fromLocal = (value: string | null | undefined): Date | null => {
  if (!value) return null;
  const parsed = new Date(value);
  return isNaN(parsed.getTime()) ? null : parsed;
};

const browserTz = (() => {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  } catch {
    return "UTC";
  }
})();

const defaultStart = (() => {
  const d = new Date();
  d.setHours(20, 0, 0, 0);
  return format(d, LOCAL_FORMAT);
})();

const addHours = (value: string, hours: number) => {
  const parsed = fromLocal(value);
  if (!parsed) return "";
  parsed.setHours(parsed.getHours() + hours);
  return format(parsed, LOCAL_FORMAT);
};

const sourceMission = ref<Mission | MissionExtended | undefined>(props.mission);
const selectedMissionSlug = ref<string | null>(props.mission?.slug ?? null);
const selectedMissionTitle = ref<string | null>(props.mission?.title ?? null);
const selectedMissionCategory = ref<string | null>(
  (props.mission?.category as string) ?? null,
);

const { defineField, handleSubmit, setValues, meta } = useForm({
  initialValues: {
    title: props.event?.title ?? props.mission?.title ?? "",
    description: props.event?.description ?? props.mission?.description ?? "",
    briefing: props.event?.briefing ?? "",
    startsAt: props.event?.startsAt
      ? toLocal(props.event.startsAt)
      : props.startsAtPrefill
        ? toLocal(props.startsAtPrefill)
        : defaultStart,
    endsAt: props.event?.endsAt
      ? toLocal(props.event.endsAt)
      : props.startsAtPrefill
        ? addHours(toLocal(props.startsAtPrefill), 2)
        : addHours(defaultStart, 2),
    timezone: props.event?.timezone ?? browserTz,
    location: props.event?.location ?? "",
    meetupLocation: props.event?.meetupLocation ?? "",
    visibility: props.event?.visibility ?? FleetEventVisibility.members,
    category:
      props.event?.category ?? props.mission?.category ?? MissionCategory.other,
    scenario:
      props.event?.scenario ??
      (props.mission as { scenario?: string | null } | undefined)?.scenario ??
      "",
    coverImage: undefined as string | undefined,
    coverImagePreset:
      props.event?.coverImagePreset ??
      (props.mission as { coverImagePreset?: string | null } | undefined)
        ?.coverImagePreset ??
      null,
    maxAttendees: props.event?.maxAttendees ?? null,
    autoLockEnabled: props.event?.autoLockEnabled ?? true,
    autoLockMinutesBefore: props.event?.autoLockMinutesBefore ?? 60,
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [briefing, briefingProps] = defineField("briefing");
const [startsAt] = defineField("startsAt");
const [endsAt] = defineField("endsAt");
const [timezone, timezoneProps] = defineField("timezone");
const [location, locationProps] = defineField("location");
const [meetupLocation, meetupLocationProps] = defineField("meetupLocation");
const [visibility, visibilityProps] = defineField("visibility");
const [category, categoryProps] = defineField("category");
const [scenario, scenarioProps] = defineField("scenario");
const [coverImage, coverImageProps] = defineField("coverImage");
const [coverImagePreset] = defineField("coverImagePreset");
const [maxAttendees, maxAttendeesProps] = defineField("maxAttendees");
const [autoLockEnabled] = defineField("autoLockEnabled");
const [autoLockMinutesBefore, autoLockMinutesBeforeProps] = defineField(
  "autoLockMinutesBefore",
);

// Keep endsAt 2 hours after startsAt unless the user has actively edited
// endsAt away from that delta — in which case we preserve their choice.
let endsAtTouched = !!props.event?.endsAt;
watch(endsAt, (newValue) => {
  const start = startsAt.value as string;
  if (!start || !newValue) return;
  if (newValue !== addHours(start, 2)) endsAtTouched = true;
});
watch(startsAt, (newStart, oldStart) => {
  if (!newStart) return;
  if (endsAtTouched) {
    return;
  }
  endsAt.value = addHours(newStart as string, 2);
  void oldStart;
});

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

const visibilityOptions = computed<FilterOption[]>(() =>
  Object.values(FleetEventVisibility).map((value) => ({
    value,
    label: t(`labels.fleets.events.visibilities.${value}`),
  })),
);

const timezoneOptions = computed<FilterOption[]>(() => {
  const base = TIMEZONE_OPTIONS.map((tz) => ({
    value: tz.value,
    label: tz.label,
  }));
  // Make sure a preserved value (e.g. an event saved with an unusual zone)
  // remains selectable.
  const current = (timezone.value as string) || "";
  if (current && !base.some((opt) => opt.value === current)) {
    base.unshift({ value: current, label: current });
  }
  return base;
});

const applyMissionPrefill = (mission: Mission | MissionExtended | null) => {
  if (!mission) {
    sourceMission.value = undefined;
    selectedMissionSlug.value = null;
    selectedMissionTitle.value = null;
    selectedMissionCategory.value = null;
    return;
  }

  sourceMission.value = mission;
  selectedMissionSlug.value = mission.slug;
  selectedMissionTitle.value = mission.title;
  selectedMissionCategory.value = mission.category as string;
  setValues({
    title: mission.title,
    description: mission.description ?? "",
    category: mission.category,
    scenario: (mission as { scenario?: string | null }).scenario ?? "",
    coverImagePreset:
      (mission as { coverImagePreset?: string | null }).coverImagePreset ??
      null,
  });
};

const openTemplatePicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/MissionTemplatePicker/index.vue"),
    props: {
      fleet: props.fleet,
      selectedSlug: selectedMissionSlug.value,
      onPick: (mission: Mission | null) => applyMissionPrefill(mission),
    },
  });
};

if (props.mission) {
  applyMissionPrefill(props.mission);
}

const existingCoverImage = computed(() => {
  return (
    props.event as
      | { coverImage?: { url?: string; mediumUrl?: string } | null }
      | undefined
  )?.coverImage;
});

const eventTeams = computed<FleetEventTeam[]>(() => {
  const teamsField = (props.event as { teams?: FleetEventTeam[] } | undefined)
    ?.teams;
  return Array.isArray(teamsField) ? teamsField : [];
});

const openAddEventTeamModal = () => {
  if (!props.event) return;
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/EventTeamModal/index.vue"),
    props: {
      fleet: props.fleet,
      event: props.event,
    },
  });
};

const createMutation = useCreateFleetEvent();
const updateMutation = useUpdateFleetEvent();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    title: values.title,
    description: values.description || undefined,
    briefing: values.briefing || undefined,
    startsAt: new Date(values.startsAt as string).toISOString(),
    endsAt: values.endsAt
      ? new Date(values.endsAt as string).toISOString()
      : null,
    timezone: values.timezone,
    location: values.location || undefined,
    meetupLocation: values.meetupLocation || undefined,
    visibility: values.visibility as never,
    category: values.category as never,
    scenario: values.scenario || null,
    coverImagePreset: values.coverImage ? null : values.coverImagePreset,
    coverImage: values.coverImage || undefined,
    maxAttendees: values.maxAttendees ? Number(values.maxAttendees) : null,
    autoLockEnabled: !!values.autoLockEnabled,
    autoLockMinutesBefore: values.autoLockEnabled
      ? Number(values.autoLockMinutesBefore || 60)
      : null,
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        slug: props.event!.slug,
        data,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        data: selectedMissionSlug.value
          ? ({ ...data, missionSlug: selectedMissionSlug.value } as never)
          : (data as never),
      });

  await mutation
    .then((response) => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleets.event.update.success")
          : t("messages.fleets.event.create.success"),
      });
      comlink.emit(
        isEdit.value ? "fleet-event-updated" : "fleet-event-created",
      );

      const targetSlug = isEdit.value ? props.event!.slug : response?.slug;
      if (targetSlug) {
        void router.push({
          name: "fleet-event",
          params: { slug: props.fleet.slug, event: targetSlug },
        });
      }
    })
    .catch(() => {
      displayAlert({
        text: isEdit.value
          ? t("messages.fleets.event.update.failure")
          : t("messages.fleets.event.create.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <form id="event-form" class="event-form" @submit.prevent="onSubmit">
    <div v-if="!isEdit" class="row">
      <div class="col-12">
        <div class="event-form__mission-prefill">
          <span class="event-form__prefill-label">
            {{ t("labels.fleets.events.fromMission") }}
          </span>
          <div v-if="selectedMissionSlug" class="event-form__prefill-active">
            <span class="event-form__prefill-name">
              <i class="fa-light fa-flag-checkered" />
              {{ selectedMissionTitle }}
              <span
                v-if="selectedMissionCategory"
                class="event-form__prefill-badge"
              >
                {{
                  t(
                    `labels.fleets.missions.categories.${selectedMissionCategory}`,
                  )
                }}
              </span>
            </span>
            <div class="event-form__prefill-actions">
              <Btn
                :size="BtnSizesEnum.SMALL"
                inline
                @click="openTemplatePicker"
              >
                <i class="fa-light fa-arrows-rotate" />
                {{ t("labels.fleets.events.changeTemplate") }}
              </Btn>
              <Btn
                :size="BtnSizesEnum.SMALL"
                inline
                variant="link"
                @click="applyMissionPrefill(null)"
              >
                <i class="fa-light fa-xmark" />
                {{ t("labels.fleets.events.clearTemplate") }}
              </Btn>
            </div>
          </div>
          <Btn
            v-else
            :size="BtnSizesEnum.SMALL"
            inline
            @click="openTemplatePicker"
          >
            <i class="fa-light fa-folder-open" />
            {{ t("labels.fleets.events.pickTemplate") }}
          </Btn>
        </div>
      </div>
    </div>

    <FormTabs>
      <FormTab
        id="basic"
        :label="t('labels.fleets.events.tabs.basic')"
        :fields="['title', 'startsAt', 'timezone']"
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
            <FormDateTime
              v-model="startsAt"
              name="startsAt"
              :rules="validationSchema.startsAt"
              :minutes-increment="15"
              :label="t('labels.fleets.events.startsAt')"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormDateTime
              v-model="endsAt"
              name="endsAt"
              :minutes-increment="15"
              :label="t('labels.fleets.events.endsAt')"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FilterGroup
              v-model="timezone"
              v-bind="timezoneProps"
              :options="timezoneOptions"
              :label="t('labels.fleets.events.timezone')"
              name="timezone"
              :searchable="true"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="maxAttendees"
              v-bind="maxAttendeesProps"
              name="maxAttendees"
              :type="InputTypesEnum.NUMBER"
              :label="t('labels.fleets.events.maxAttendees')"
            />
          </div>
        </div>

        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="location"
              v-bind="locationProps"
              name="location"
              :label="t('labels.fleets.events.location')"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="meetupLocation"
              v-bind="meetupLocationProps"
              name="meetupLocation"
              :label="t('labels.fleets.events.meetupLocation')"
            />
          </div>
        </div>

        <div class="row">
          <div class="col-12 col-md-6">
            <FilterGroup
              v-model="visibility"
              v-bind="visibilityProps"
              :options="visibilityOptions"
              :label="t('labels.fleets.events.visibility')"
              name="visibility"
              :searchable="false"
            />
          </div>
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
        </div>
        <div class="row">
          <div class="col-12">
            <FormInput
              v-model="scenario"
              v-bind="scenarioProps"
              name="scenario"
              :label="t('labels.fleets.missions.scenario')"
              list="event-scenario-suggestions"
              autocomplete="off"
            />
            <datalist id="event-scenario-suggestions">
              <option
                v-for="suggestion in scenarioSuggestions"
                :key="suggestion"
                :value="suggestion"
              />
            </datalist>
          </div>
        </div>

        <div class="row">
          <div class="col-12 col-md-6">
            <FormCheckbox
              v-model="autoLockEnabled"
              name="autoLockEnabled"
              :label="t('labels.fleets.events.autoLockEnabled')"
            />
          </div>
          <div v-if="autoLockEnabled" class="col-12 col-md-6">
            <FormInput
              v-model="autoLockMinutesBefore"
              v-bind="autoLockMinutesBeforeProps"
              name="autoLockMinutesBefore"
              :type="InputTypesEnum.NUMBER"
              :label="t('labels.fleets.events.autoLockMinutesBefore')"
            />
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
        <div class="event-teams-section__header">
          <Btn :inline="true" size="small" @click="openAddEventTeamModal">
            <i class="fa-light fa-plus" />
            <span>{{ t("actions.fleets.events.addTeam") }}</span>
          </Btn>
        </div>
        <div class="event-teams">
          <EventTeamCard
            v-for="team in eventTeams"
            :key="team.id"
            :team="team"
            :event="props.event!"
            :fleet="fleet"
            editable
            is-manager
          />
        </div>
        <p v-if="!eventTeams.length" class="text-muted">
          {{ t("labels.fleets.missions.noTeams") }}
        </p>
      </FormTab>

      <FormActions
        :submitting="submitting"
        form-id="event-form"
        :dirty="meta.dirty || meta.touched"
        @cancel="emit('cancel')"
      />
    </FormTabs>
  </form>
</template>

<style lang="scss" scoped>
.event-form {
  width: 100%;
}
.event-form__mission-prefill {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  background: rgba(255, 255, 255, 0.03);
  padding: 0.7rem 0.85rem;
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.07);
}
.event-form__prefill-label {
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}
.event-form__prefill-active {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  flex-wrap: wrap;
}
.event-form__prefill-name {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;

  i {
    color: var(--text-muted);
  }
}
.event-form__prefill-badge {
  font-size: 0.65rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 0.1rem 0.4rem;
  border-radius: 999px;
  background: rgba(74, 170, 170, 0.18);
  color: var(--accent, #4aa);
}
.event-form__prefill-actions {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
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
.event-teams-section__header {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 0.75rem;
}
.event-teams {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
