<script lang="ts">
export default {
  name: "FleetSquadronModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { VSwatches } from "vue3-swatches";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetSquadron,
  useCreateFleetSquadron,
  useUpdateFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron?: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();

const isEdit = computed(() => !!props.squadron);
const submitting = ref(false);

const validationSchema = {
  name: "required|min:2|max:255",
  // What the card carries, so it stays short.
  shortDescription: "max:255",
  description: "max:5000",
};

const { defineField, handleSubmit, setErrors } = useForm({
  initialValues: {
    name: props.squadron?.name ?? "",
    shortDescription: props.squadron?.shortDescription ?? "",
    description: props.squadron?.description ?? "",
    // The picker cannot express "no colour", so a squadron without one opens
    // on the neutral it is already drawn with rather than on the browser's
    // default black.
    color: props.squadron?.color ?? "#8899aa",
    icon: undefined as string | undefined,
    logo: undefined as string | undefined,
    header: undefined as string | undefined,
  },
});

const [name, nameProps] = defineField("name");
const [shortDescription, shortDescriptionProps] =
  defineField("shortDescription");
const [description, descriptionProps] = defineField("description");
const [color, colorProps] = defineField("color");
const [icon, iconProps] = defineField("icon");
const [logo, logoProps] = defineField("logo");
const [header, headerProps] = defineField("header");

const createMutation = useCreateFleetSquadron();
const updateMutation = useUpdateFleetSquadron();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    name: values.name,
    shortDescription: values.shortDescription || null,
    description: values.description || null,
    color: values.color || null,
    // Passed through rather than coerced: `undefined` keeps what is attached,
    // `null` is the field saying it was cleared, and a signed id replaces it.
    icon: values.icon,
    logo: values.logo,
    header: values.header,
  };

  const mutation = isEdit.value
    ? updateMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        slug: props.squadron!.slug,
        data,
      })
    : createMutation.mutateAsync({
        fleetSlug: props.fleet.slug,
        data,
      });

  await mutation
    .then(() => {
      displaySuccess({
        text: isEdit.value
          ? t("messages.fleet.squadrons.update.success")
          : t("messages.fleet.squadrons.create.success"),
      });
      comlink.emit(
        isEdit.value ? "fleet-squadron-updated" : "fleet-squadron-created",
      );
      comlink.emit("close-modal");
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text:
          message ||
          (isEdit.value
            ? t("messages.fleet.squadrons.update.failure")
            : t("messages.fleet.squadrons.create.failure")),
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
        ? t('headlines.fleets.squadrons.edit')
        : t('headlines.fleets.squadrons.create')
    "
  >
    <form id="fleet-squadron-form" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormFileInput
            v-model="icon"
            v-bind="iconProps"
            :file="props.squadron?.icon"
            name="icon"
            :label="t('labels.fleet.squadrons.icon')"
            :info="t('labels.fleet.squadrons.iconHint')"
            :allowed-types="AllowedFileTypes.IMAGE"
            clearable
          />
        </div>
        <div class="col-12 col-md-6">
          <FormFileInput
            v-model="logo"
            v-bind="logoProps"
            :file="props.squadron?.logo"
            name="logo"
            :label="t('labels.fleet.squadrons.logo')"
            :info="t('labels.fleet.squadrons.logoHint')"
            :allowed-types="AllowedFileTypes.IMAGE"
            clearable
          />
        </div>
      </div>
      <FormFileInput
        v-model="header"
        v-bind="headerProps"
        :file="props.squadron?.header"
        name="header"
        :label="t('labels.fleet.squadrons.header')"
        :info="t('labels.fleet.squadrons.headerHint')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        :rules="validationSchema.name"
        :label="t('labels.fleet.squadrons.name')"
      />
      <FormTextarea
        v-model="shortDescription"
        v-bind="shortDescriptionProps"
        name="shortDescription"
        :rules="validationSchema.shortDescription"
        :label="t('labels.fleet.squadrons.shortDescription')"
        :info="t('labels.fleet.squadrons.shortDescriptionHint')"
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :rules="validationSchema.description"
        :label="t('labels.fleet.squadrons.description')"
        :info="t('labels.fleet.squadrons.descriptionHint')"
      />
      <FormInput
        v-model="color"
        v-bind="colorProps"
        name="color"
        :type="InputTypesEnum.COLOR"
        :label="t('labels.fleet.squadrons.color')"
      />
      <VSwatches v-model="color" :inline="true" />
    </form>

    <template #footer>
      <div class="modal-actions">
        <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
