<script lang="ts">
export default {
  name: "VehicleLocationModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import LocationInput from "@/shared/components/LocationInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const vehicle = computed(() => props.vehicle);

const { defineField, handleSubmit } = useForm({
  initialValues: {
    location: props.vehicle.location ?? "",
    locationId: props.vehicle.linkedLocation?.id ?? null,
  },
});

const [location] = defineField("location");
const [locationId] = defineField("locationId");

const { useUpdateMutation } = useVehicleMutations();
const updateMutation = useUpdateMutation(vehicle);

const onSubmit = handleSubmit(async (values) => {
  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      // Null rather than left out: a cleared field clears the place.
      data: {
        location: values.location || null,
        locationId: values.locationId ?? null,
      },
    })
    .then(() => comlink.emit("close-modal"))
    .catch(() => {
      displayAlert({ text: t("messages.vehicleOverview.location.failure") });
    });
});
</script>

<template>
  <Modal :title="t('headlines.vehicleOverview.location')">
    <form id="vehicle-location-form" @submit.prevent="onSubmit">
      <LocationInput
        v-model="location"
        v-model:location-id="locationId"
        :linked="vehicle.linkedLocation"
        name="location"
        :label="t('labels.vehicleOverview.location')"
      />
      <p class="text-muted">{{ t("texts.vehicleOverview.locationPrivate") }}</p>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="vehicle-location-form"
        :loading="updateMutation.isPending.value"
        data-test="vehicle-location-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
