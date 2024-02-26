<template>
  <transition name="fade">
    <div v-if="!online" class="network-status">
      {{ t("labels.networkStatusOffline") }}
    </div>
  </transition>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import { useAppStore } from "@/frontend/stores/app";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const appStore = useAppStore();

const { online } = storeToRefs(appStore);

const checkOnline = () => {
  appStore.online = window.navigator.onLine;
};

checkOnline();

onMounted(() => {
  window.addEventListener("online", checkOnline);
  window.addEventListener("offline", checkOnline);
});

onBeforeUnmount(() => {
  window.removeEventListener("online", checkOnline);
  window.removeEventListener("offline", checkOnline);
});
</script>

<script lang="ts">
export default {
  name: "NetworkStatus",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
