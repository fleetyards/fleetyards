<template>
  <div id="app" class="app-body container-fluid">
    <router-view v-slot="{ Component, route }">
      <transition name="fade" mode="out-in">
        <component :is="Component" :key="`${locale}-${route.path}`" />
      </transition>
    </router-view>
    <AppModal />
  </div>
</template>

<script lang="ts" setup>
import AppModal from "@/shared/components/AppModal/index.vue";
import { useI18nStore } from "@/shared/stores/i18n";
import { useAppStore } from "@/admin/stores/app";
import { storeToRefs } from "pinia";

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

const appStore = useAppStore();

onMounted(() => {
  window.addEventListener("resize", checkMobile);
  checkMobile();
});

onUnmounted(() => {
  window.removeEventListener("resize", checkMobile);
});

const checkMobile = () => {
  appStore.mobile = document.documentElement.clientWidth < 992;
};
</script>

<script lang="ts">
export default {
  name: "AdminApp",
};
</script>
