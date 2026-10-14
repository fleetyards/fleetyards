<script lang="ts">
export default { name: "LocationSetShipLocationModal" };
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  hangar,
  type Hangar,
  type Vehicle,
  type Location,
  useUpdateVehicle,
} from "@/services/fyApi";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const props = defineProps<{ location: Location }>();
const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();
const vehicleId = ref<string | null>(null);
const mutation = useUpdateVehicle();
const { invalidateHangarQueries, invalidateVehiclePage } =
  useVehicleMutations();
const fetchVehicles = ({ search, page }: BaseSelectParams<Vehicle>) =>
  hangar({
    page: String(page ?? 1),
    q: { searchCont: search, hiddenByUserEq: "true" },
  });
const formatVehicles = (response: Hangar) =>
  response.items.map((vehicle) => ({
    value: vehicle.id,
    label: [vehicle.name || vehicle.model.name, vehicle.serial]
      .filter(Boolean)
      .join(" · "),
  }));

const save = async () => {
  if (!vehicleId.value || mutation.isPending.value) return;
  try {
    const vehicle = await mutation.mutateAsync({
      id: vehicleId.value,
      data: {
        locationId: props.location.id,
        location: props.location.name ?? null,
      },
    });
    void invalidateHangarQueries();
    void invalidateVehiclePage(vehicle);
    displaySuccess({ text: t("labels.location.setLocationSuccess") });
    comlink.emit("close-modal");
  } catch {
    displayAlert({ text: t("labels.location.setLocationFailure") });
  }
};
</script>

<template>
  <Modal :title="t('labels.location.setLocation')">
    <p>{{ location.name }}</p>
    <BaseSelect
      v-model="vehicleId"
      name="locationVehicle"
      :label="t('labels.fleets.events.myVehicle')"
      :query-fn="fetchVehicles"
      :query-response-formatter="formatVehicles"
      searchable
      paginated
    />
    <template #footer>
      <Btn
        :disabled="!vehicleId"
        :loading="mutation.isPending.value"
        data-test="save-ship-location"
        @click="save"
      >
        {{ t("labels.location.setLocation") }}
      </Btn>
    </template>
  </Modal>
</template>
