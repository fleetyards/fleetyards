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

const config = window.fleetyards_config ? window.fleetyards_config() : {};

const ships = ref<string[]>(config.ships || []);
const users = ref<string[]>(config.users || []);
const fleetId = ref<string | undefined>(config.fleetId || config.fleetID);
const groupedButton = ref<boolean>(config.groupedButton || false);
const fleetchartSlider = ref<boolean>(config.fleetchartSlider || false);

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
