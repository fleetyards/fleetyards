<script lang="ts">
export default {
  name: "FleetEventOccurrenceOverrideModal",
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
  type FleetEvent,
  useUpdateFleetEventOccurrence,
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
    scenario: props.initial?.scenario ?? "",
  },
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [location, locationProps] = defineField("location");
const [meetupLocation, meetupLocationProps] = defineField("meetupLocation");
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
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.fleets.events.description')"
      />
      <FormInput
        v-model="location"
        v-bind="locationProps"
        name="location"
        :label="t('labels.fleets.events.location')"
      />
      <FormInput
        v-model="meetupLocation"
        v-bind="meetupLocationProps"
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

<style lang="scss" scoped>
.override-form {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
</style>
