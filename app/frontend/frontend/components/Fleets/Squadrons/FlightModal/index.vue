<script lang="ts">
export default {
  name: "FleetSquadronFlightModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormMarkdownEditor from "@/shared/components/base/FormMarkdownEditor/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { SHORT_DESCRIPTION_MAX } from "@/frontend/composables/useSquadronForm";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import {
  type FleetSquadronFlight,
  useCreateFleetSquadronFlight,
  useUpdateFleetSquadronFlight,
} from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  squadronSlug: string;
  flight?: FleetSquadronFlight;
};

const props = withDefaults(defineProps<Props>(), { flight: undefined });

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const router = useRouter();

const isEdit = computed(() => !!props.flight);

const initialValues = {
  name: props.flight?.name ?? "",
  shortDescription: props.flight?.shortDescription ?? "",
  description: props.flight?.description ?? "",
  coverImage: undefined as string | null | undefined,
};

const { defineField, handleSubmit, values, setErrors } = useForm({
  initialValues,
});

useModalDirty(useFormDirty(values, initialValues));

const [name, nameProps] = defineField("name");
const [shortDescription, shortDescriptionProps] =
  defineField("shortDescription");
const [description, descriptionProps] = defineField("description");
const [coverImage, coverImageProps] = defineField("coverImage");

const createMutation = useCreateFleetSquadronFlight();
const updateMutation = useUpdateFleetSquadronFlight();

const submitting = ref(false);

const onSubmit = handleSubmit(async (formValues) => {
  submitting.value = true;

  const data = {
    name: formValues.name,
    shortDescription: formValues.shortDescription || null,
    description: formValues.description || null,
    // undefined keeps the attached cover, null removes it, a signed id replaces it.
    coverImage: formValues.coverImage,
  };

  const request = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleetSlug,
        fleetSquadronSlug: props.squadronSlug,
        id: props.flight!.id,
        data,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleetSlug,
        fleetSquadronSlug: props.squadronSlug,
        data,
      });

  await request
    .then((saved) => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleet.squadrons.flights.update.success")
          : t("messages.fleet.squadrons.flights.create.success"),
      });
      comlink.emit("mission-children-changed");
      comlink.emit("close-modal", true);

      if (!isEdit.value) {
        void router.push({
          name: "fleet-squadron-flight",
          params: {
            slug: props.fleetSlug,
            squadron: props.squadronSlug,
            flight: saved.id,
          },
        });
      }
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);
      setErrors(formErrors);
      displayAlert({
        text:
          message ||
          (isEdit.value
            ? t("messages.fleet.squadrons.flights.update.failure")
            : t("messages.fleet.squadrons.flights.create.failure")),
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
        ? t('headlines.fleets.squadrons.flights.edit')
        : t('headlines.fleets.squadrons.flights.create')
    "
  >
    <form id="flight-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        rules="required"
        :label="t('labels.fleet.squadrons.flights.name')"
      />
      <FormTextarea
        v-model="shortDescription"
        v-bind="shortDescriptionProps"
        name="shortDescription"
        :rules="`max:${SHORT_DESCRIPTION_MAX}`"
        :maxlength="SHORT_DESCRIPTION_MAX"
        :label="t('labels.fleet.squadrons.flights.shortDescription')"
        :info="t('labels.fleet.squadrons.flights.shortDescriptionHint')"
      />
      <FormFileInput
        v-model="coverImage"
        v-bind="coverImageProps"
        :file="flight?.coverImage ?? undefined"
        name="coverImage"
        :label="t('labels.fleet.squadrons.flights.coverImage')"
        :info="t('labels.fleet.squadrons.flights.coverImageHint')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
      <FormMarkdownEditor
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('labels.fleet.squadrons.flights.description')"
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="flight-form"
        :loading="submitting"
        data-test="flight-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
