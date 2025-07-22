<template>
  <router-view
    :key="locale"
    :ships="ships"
    :users="users"
    :fleet-id="fleetId"
    :grouped-button="groupedButton"
    :fleetchart-slider="fleetchartSlider"
  />
</template>

<script lang="ts" setup>
import { useI18nStore } from "@/shared/stores/i18n";
import { useEmbedStore } from "@/embed/stores/embed";
import { storeToRefs } from "pinia";
import { useCheckStoreVersion } from "@/shared/composables/useCheckStoreVersion";

const config = computed(() => window.FleetYardsFleetchartConfig || {});

const ships = ref<string[]>(config.value.ships || []);
const users = ref<string[]>(config.value.users || []);
const fleetId = ref<string | undefined>(
  config.value.fleetId || config.value.fleetID,
);
const groupedButton = ref<boolean>(config.value.groupedButton || false);
const fleetchartSlider = ref<boolean>(config.value.fleetchartSlider || false);

const updateShips = (newShips: string[]) => {
  ships.value = newShips;
};

const updateUsers = (newUsers: string[]) => {
  users.value = newUsers;
};

const updateFleet = (newFleetID: string) => {
  fleetId.value = newFleetID;
};

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

const embedStore = useEmbedStore();

useCheckStoreVersion(embedStore);

defineExpose({
  updateShips,
  updateUsers,
  updateFleet,
});
</script>

<script lang="ts">
export default {
  name: "FleetyardsEmbedApp",
};
</script>
