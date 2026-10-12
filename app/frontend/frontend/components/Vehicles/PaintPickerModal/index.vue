<script lang="ts">
export default {
  name: "VehiclePaintPickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import VehiclePaintPicker from "@/frontend/components/Vehicles/PaintPicker/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useQueryClient } from "@tanstack/vue-query";
import { type Vehicle, getVehiclePaintsQueryKey } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();
const { displayAlert } = useAppNotifications();

const vehicle = computed(() => props.vehicle);

const paintId = ref<string | null>(props.vehicle.paint?.id ?? null);

const { useUpdateMutation } = useVehicleMutations();
const updateMutation = useUpdateMutation(vehicle);

const save = async () => {
  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      data: { modelPaintId: paintId.value },
    })
    .then(async () => {
      await queryClient.invalidateQueries({
        queryKey: getVehiclePaintsQueryKey(props.vehicle.id),
      });
      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({ text: t("messages.vehicleOverview.paint.failure") });
    });
};
</script>

<template>
  <Modal
    :title="
      t('headlines.vehicleOverview.paints', { model: vehicle.model.name })
    "
  >
    <VehiclePaintPicker
      v-model="paintId"
      :model-slug="vehicle.model.slug"
      :default-image="vehicle.model.media.storeImage?.smallUrl"
      hide-legend
    />

    <template #footer>
      <Btn
        :loading="updateMutation.isPending.value"
        data-test="paint-picker-save"
        @click="save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
