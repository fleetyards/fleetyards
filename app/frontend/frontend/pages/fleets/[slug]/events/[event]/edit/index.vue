<script lang="ts">
export default {
  name: "FleetEventEditBasicPage",
};
</script>

<script lang="ts" setup>
import { useForm, type SubmissionHandler } from "vee-validate";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import EventEditFormShell from "@/frontend/components/Fleets/Events/EventEditFormShell/index.vue";
import {
  type Fleet,
  type FilterOption,
  type FleetEventExtended,
  type FleetEventUpdateInput,
  FleetEventVisibility,
  MissionCategory,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionScenarios } from "@/frontend/composables/useMissionScenarios";
import { TIMEZONE_OPTIONS } from "@/shared/utils/Timezones";
import { format, parseISO } from "date-fns";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const LOCAL_FORMAT = "yyyy-MM-dd'T'HH:mm";

const toLocal = (iso: string | null | undefined) => {
  if (!iso) return "";
  try {
    return format(parseISO(iso), LOCAL_FORMAT);
  } catch {
    return "";
  }
};

const validationSchema = {
  title: "required|min:2",
  startsAt: "required",
  timezone: "required",
};

const { defineField, handleSubmit, meta, setErrors } =
  useForm<FleetEventUpdateInput>({
    initialValues: {
      title: props.event.title,
      startsAt: toLocal(props.event.startsAt) as never,
      endsAt: toLocal(props.event.endsAt) as never,
      timezone: props.event.timezone,
      location: props.event.location ?? "",
      meetupLocation: props.event.meetupLocation ?? "",
      visibility: props.event.visibility,
      category: props.event.category,
      scenario: props.event.scenario ?? "",
      maxAttendees: props.event.maxAttendees ?? null,
      autoLockEnabled: props.event.autoLockEnabled ?? true,
      autoLockMinutesBefore: props.event.autoLockMinutesBefore ?? 60,
    },
    validationSchema,
  });

const [title, titleProps] = defineField("title");
const [startsAt] = defineField("startsAt");
const [endsAt] = defineField("endsAt");
const [timezone, timezoneProps] = defineField("timezone");
const [location, locationProps] = defineField("location");
const [meetupLocation, meetupLocationProps] = defineField("meetupLocation");
const [visibility, visibilityProps] = defineField("visibility");
const [category, categoryProps] = defineField("category");
const [scenario, scenarioProps] = defineField("scenario");
const [maxAttendees, maxAttendeesProps] = defineField("maxAttendees");
const [autoLockEnabled] = defineField("autoLockEnabled");
const [autoLockMinutesBefore, autoLockMinutesBeforeProps] = defineField(
  "autoLockMinutesBefore",
);

const { suggestions: scenarioSuggestions } = useMissionScenarios();

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
  const current = (timezone.value as string) || "";
  if (current && !base.some((opt) => opt.value === current)) {
    base.unshift({ value: current, label: current });
  }
  return base;
});

const addHours = (value: string, hours: number) => {
  if (!value) return "";
  const parsed = new Date(value);
  if (isNaN(parsed.getTime())) return "";
  parsed.setHours(parsed.getHours() + hours);
  return format(parsed, LOCAL_FORMAT);
};

let endsAtTouched = !!props.event.endsAt;
watch(endsAt, (newValue) => {
  const start = startsAt.value as string;
  if (!start || !newValue) return;
  if (newValue !== addHours(start, 2)) endsAtTouched = true;
});
watch(startsAt, (newStart) => {
  if (!newStart || endsAtTouched) return;
  endsAt.value = addHours(newStart as string, 2) as never;
});

// vee-validate gives us back local datetime strings; the API wants ISO.
// Wrap the submit handler so payload values are correctly typed.
const wrapHandleSubmit = (cb: SubmissionHandler<FleetEventUpdateInput>) =>
  handleSubmit((values, ctx) => {
    return cb(
      {
        ...values,
        startsAt: values.startsAt
          ? (new Date(values.startsAt as string).toISOString() as never)
          : undefined,
        endsAt: values.endsAt
          ? (new Date(values.endsAt as string).toISOString() as never)
          : null,
        scenario: values.scenario || null,
        maxAttendees: values.maxAttendees ? Number(values.maxAttendees) : null,
        autoLockMinutesBefore: values.autoLockEnabled
          ? Number(values.autoLockMinutesBefore || 60)
          : null,
        location: values.location || undefined,
        meetupLocation: values.meetupLocation || undefined,
      },
      ctx,
    );
  });
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.events.editBasic") }}</Heading>
  <EventEditFormShell
    :fleet="fleet"
    :event="event"
    :handle-submit="wrapHandleSubmit"
    :meta="meta"
    :set-errors="setErrors"
    form-id="fleet-event-edit-basic"
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
  </EventEditFormShell>
</template>
