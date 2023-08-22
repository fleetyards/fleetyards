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

const checkStoreVersion = () => {
  if (embedStore.storeVersion !== window.STORE_VERSION) {
    console.info("Updating Store Version and resetting Store");

    embedStore.$reset();
    embedStore.storeVersion = window.STORE_VERSION;
  }
};

onBeforeMount(() => {
  checkStoreVersion();
});

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
