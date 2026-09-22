<script lang="ts">
export default {
  name: "FleetSquadronImagesForm",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type FleetSquadron,
  useUpdateFleetSquadron,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  squadron: FleetSquadron;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const router = useRouter();

const submitting = ref(false);

const { defineField, handleSubmit, setErrors, meta } = useForm({
  initialValues: {
    icon: undefined as string | undefined,
    logo: undefined as string | undefined,
    header: undefined as string | undefined,
  },
});

const [icon, iconProps] = defineField("icon");
const [logo, logoProps] = defineField("logo");
const [header, headerProps] = defineField("header");

const mutation = useUpdateFleetSquadron();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      slug: props.squadron.slug,
      data: {
        // Passed through rather than coerced: `undefined` keeps what is
        // attached, `null` is the field saying it was cleared, and a signed id
        // replaces it.
        icon: values.icon,
        logo: values.logo,
        header: values.header,
      },
    })
    .then(() => {
      displaySuccess({ text: t("messages.fleet.squadrons.update.success") });
      comlink.emit("fleet-squadron-updated");

      void router.push({
        name: "fleet-squadron",
        params: { slug: props.fleet.slug, squadron: props.squadron.slug },
      });
    })
    .catch((error) => {
      const { message, formErrors } = validationErrorFrom(error);

      setErrors(formErrors);

      displayAlert({
        text: message || t("messages.fleet.squadrons.update.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = () => {
  void router.push({
    name: "fleet-squadron",
    params: { slug: props.fleet.slug, squadron: props.squadron.slug },
  });
};
</script>

<template>
  <form id="fleet-squadron-images-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormFileInput
          v-model="icon"
          v-bind="iconProps"
          :file="squadron.icon"
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
          :file="squadron.logo"
          name="logo"
          :label="t('labels.fleet.squadrons.logo')"
          :info="t('labels.fleet.squadrons.logoHint')"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
    </div>

    <hr />

    <div class="row">
      <div class="col-12">
        <FormFileInput
          v-model="header"
          v-bind="headerProps"
          :file="squadron.header"
          name="header"
          :label="t('labels.fleet.squadrons.header')"
          :info="t('labels.fleet.squadrons.headerHint')"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
    </div>

    <FormActions
      :submitting="submitting"
      form-id="fleet-squadron-images-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
