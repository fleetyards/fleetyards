<template>
  <transition name="fade">
    <div v-if="!online" class="network-status">
      {{ t("labels.networkStatusOffline") }}
    </div>
  </transition>
</template>

<script lang="ts" setup>
import Store from "@/frontend/lib/Store";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

const online = computed(() => Store.getters.online);

const checkOnline = () => {
  Store.commit("setOnlineStatus", window.navigator.onLine);
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
