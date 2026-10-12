<script lang="ts">
export default {
  name: "VehicleImageModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import {
  type FieldError,
  type Vehicle,
  useUpdateVehicle,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const { invalidateVehiclePage, invalidateHangarQueries } =
  useVehicleMutations();

const { defineField, handleSubmit } = useForm({
  initialValues: {
    image: undefined as string | null | undefined,
  },
});

const [image, imageProps] = defineField("image");

// The stock render this picture replaces, so the field shows what an empty
// upload falls back to rather than a blank dropzone.
const stockImage = computed(
  () =>
    props.vehicle.paint?.media.storeImage?.smallUrl ||
    props.vehicle.upgrade?.media.storeImage?.smallUrl ||
    props.vehicle.model.media.storeImage?.smallUrl,
);

// Not the hangar's optimistic update: that merges the request into the cached
// vehicle, and the request carries a signed blob id where the vehicle holds a
// file.
const { mutateAsync, isPending: submitting } = useUpdateVehicle();

const onSubmit = handleSubmit(async (values) => {
  // `undefined` means the field was never touched, so there is nothing to save.
  if (values.image === undefined) {
    comlink.emit("close-modal");
    return;
  }

  await mutateAsync({
    id: props.vehicle.id,
    data: { image: values.image },
  })
    .then(async (updatedVehicle) => {
      await Promise.all([
        invalidateVehiclePage(updatedVehicle),
        invalidateHangarQueries(),
      ]);

      displaySuccess({ text: t("messages.vehicleOverview.image.success") });
      comlink.emit("close-modal");
    })
    .catch((error: { response?: { data?: { errors?: FieldError[] } } }) => {
      // The attachment's own reason -- an SVG, say -- is what tells the owner
      // which file would work instead.
      const reason = error.response?.data?.errors?.find(
        (fieldError) => fieldError.attribute === "image",
      )?.messages[0]?.message;

      displayAlert({
        text: [t("messages.vehicleOverview.image.failure"), reason]
          .filter(Boolean)
          .join(": "),
      });
    });
});
</script>

<template>
  <Modal :title="t('headlines.vehicleOverview.picture')">
    <form id="vehicle-image-form" @submit.prevent="onSubmit">
      <FormFileInput
        v-model="image"
        v-bind="imageProps"
        :file="vehicle.image"
        :preview-src="vehicle.image ? undefined : stockImage"
        name="image"
        :label="t('labels.vehicleOverview.picture')"
        :info="t('labels.vehicleOverview.pictureInfo')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="vehicle-image-form"
        :loading="submitting"
        data-test="vehicle-image-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
