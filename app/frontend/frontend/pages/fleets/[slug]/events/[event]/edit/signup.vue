<script lang="ts">
export default {
  name: "FleetEventEditSignupPage",
};
</script>

<script lang="ts" setup>
import { useForm, type SubmissionHandler } from "vee-validate";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import EventEditFormShell from "@/frontend/components/Fleets/Events/EventEditFormShell/index.vue";
import {
  type Fleet,
  type FilterOption,
  type FleetEventExtended,
  type FleetEventUpdateInput,
  FleetEventVisibilityEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
  event: FleetEventExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { defineField, handleSubmit, meta, setErrors } =
  useForm<FleetEventUpdateInput>({
    initialValues: {
      location: props.event.location ?? "",
      meetupLocation: props.event.meetupLocation ?? "",
      visibility: props.event.visibility,
      maxAttendees: props.event.maxAttendees ?? null,
      autoLockEnabled: props.event.autoLockEnabled ?? true,
      autoLockMinutesBefore: props.event.autoLockMinutesBefore ?? 60,
    },
  });

const [location, locationProps] = defineField("location");
const [meetupLocation, meetupLocationProps] = defineField("meetupLocation");
const [visibility, visibilityProps] = defineField("visibility");
const [maxAttendees, maxAttendeesProps] = defineField("maxAttendees");
const [autoLockEnabled] = defineField("autoLockEnabled");
const [autoLockMinutesBefore, autoLockMinutesBeforeProps] = defineField(
  "autoLockMinutesBefore",
);

const visibilityOptions = computed<FilterOption[]>(() =>
  Object.values(FleetEventVisibilityEnum).map((value) => ({
    value,
    label: t(`labels.fleets.events.visibilities.${value}`),
  })),
);

const wrapHandleSubmit = (cb: SubmissionHandler<FleetEventUpdateInput>) =>
  handleSubmit((values, ctx) =>
    cb(
      {
        ...values,
        location: values.location || undefined,
        meetupLocation: values.meetupLocation || undefined,
        maxAttendees: values.maxAttendees ? Number(values.maxAttendees) : null,
        // The number only means anything while the lock is on, and the API
        // refuses one without it.
        autoLockMinutesBefore: values.autoLockEnabled
          ? Number(values.autoLockMinutesBefore || 60)
          : null,
      } as never,
      ctx,
    ),
  );
</script>

<template>
  <Heading hero>{{ t("headlines.fleets.events.editSignup") }}</Heading>
  <EventEditFormShell
    :fleet="fleet"
    :event="event"
    :handle-submit="wrapHandleSubmit"
    :meta="meta"
    :set-errors="setErrors"
    form-id="fleet-event-edit-signup"
  >
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
        <BaseSelect
          v-model="visibility"
          v-bind="visibilityProps"
          :options="visibilityOptions"
          :label="t('labels.fleets.events.visibility')"
          name="visibility"
          :searchable="false"
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
        <FormCheckbox
          v-model="autoLockEnabled"
          name="autoLockEnabled"
          :label="t('labels.fleets.events.autoLockEnabled')"
          align-with-fields
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
