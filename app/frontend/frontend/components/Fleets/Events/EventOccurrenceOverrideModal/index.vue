<script lang="ts">
export default {
  name: "FleetEventOccurrenceOverrideModal",
};
</script>

<script lang="ts" setup>
import LocationInput from "@/shared/components/LocationInput/index.vue";
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormMarkdownEditor from "@/shared/components/base/FormMarkdownEditor/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetEvent,
  useUpdateFleetEventOccurrence,
  type LocationLink,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  event: FleetEvent;
  occurrenceDate: string;
  initial?: {
    title?: string | null;
    description?: string | null;
    location?: string | null;
    meetupLocation?: string | null;
    linkedLocation?: LocationLink | null;
    linkedMeetupLocation?: LocationLink | null;
    scenario?: string | null;
  };
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const submitting = ref(false);

const { defineField, handleSubmit } = useForm({
  initialValues: {
    title: props.initial?.title ?? "",
    description: props.initial?.description ?? "",
    location: props.initial?.location ?? "",
    meetupLocation: props.initial?.meetupLocation ?? "",
    locationId: props.initial?.linkedLocation?.id ?? null,
    meetupLocationId: props.initial?.linkedMeetupLocation?.id ?? null,
    scenario: props.initial?.scenario ?? "",
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [location] = defineField("location");
const [meetupLocation] = defineField("meetupLocation");
const [locationId] = defineField("locationId");
const [meetupLocationId] = defineField("meetupLocationId");
const [scenario, scenarioProps] = defineField("scenario");

const mutation = useUpdateFleetEventOccurrence();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.event.slug,
      data: {
        date: props.occurrenceDate,
        title: values.title || null,
        description: values.description || null,
        location: values.location || null,
        meetupLocation: values.meetupLocation || null,
        locationId: values.locationId ?? null,
        meetupLocationId: values.meetupLocationId ?? null,
        scenario: values.scenario || null,
      } as never,
    });
    displaySuccess({
      text: t("messages.fleets.event.update.success"),
    });
    comlink.emit("fleet-event-updated");
    comlink.emit("close-modal");
  } catch {
    displayAlert({
      text: t("messages.fleets.event.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal
    :title="
      t('labels.fleets.events.overrideOccurrence', { date: occurrenceDate })
    "
  >
    <form
      id="event-occurrence-override-form"
      class="override-form"
      @submit.prevent="onSubmit"
    >
      <p class="text-muted small">
        {{ t("labels.fleets.events.overrideOccurrenceHint") }}
      </p>
      <FormInput
        v-model="title"
        v-bind="titleProps"
        name="title"
        :label="t('labels.fleets.events.title')"
      />
      <FormMarkdownEditor
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.fleets.events.description')"
      />
      <LocationInput
        v-model="location"
        v-model:location-id="locationId"
        :linked="initial?.linkedLocation"
        name="location"
        :label="t('labels.fleets.events.location')"
      />
      <LocationInput
        v-model="meetupLocation"
        v-model:location-id="meetupLocationId"
        :linked="initial?.linkedMeetupLocation"
        name="meetupLocation"
        :label="t('labels.fleets.events.meetupLocation')"
      />
      <FormInput
        v-model="scenario"
        v-bind="scenarioProps"
        name="scenario"
        :label="t('labels.fleets.missions.scenario')"
      />
    </form>

    <template #footer>
      <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.override-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
</style>
