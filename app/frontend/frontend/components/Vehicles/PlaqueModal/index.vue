<script lang="ts">
export default {
  name: "VehiclePlaqueModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import PlaqueDownloadBtn from "@/frontend/components/Vehicles/PlaqueDownloadBtn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type VehiclePublic } from "@/services/fyApi";

type Props = {
  vehicle: VehiclePublic;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Modal :title="t('headlines.vehiclePlaque.title')">
    <VehiclePlaque :vehicle="vehicle" :captain="vehicle.username" />

    <template #footer>
      <PlaqueDownloadBtn
        :element="`vehicle-plaque-${vehicle.id}`"
        :filename="`plaque-${vehicle.serial || vehicle.model.slug}`"
        data-test="vehicle-plaque-download"
      />
    </template>
  </Modal>
</template>
