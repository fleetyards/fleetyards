<script lang="ts">
export default {
  name: "AdminApp",
};
</script>

<script lang="ts" setup>
import AppModal from "@/shared/components/AppModal/index.vue";
import { useI18nStore } from "@/shared/stores/i18n";
import { useAppStore } from "@/admin/stores/app";
import { storeToRefs } from "pinia";
import { useNProgress } from "@/shared/composables/useNProgress";

useNProgress();

const route = useRoute();

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

<template>
  <div
    id="app"
    :key="locale"
    :class="{
      [`page-${String(route.name)}`]: true,
    }"
    class="flex flex-col min-h-screen"
  >
    <div class="flex items-stretch">
      <div class="flex flex-1 flex-col max-w-full h-full">
        <div class="min-h-screen">
          <router-view v-slot="{ Component, route: viewRoute }">
            <transition name="fade" mode="out-in">
              <section
                class="px-4 relative left-0 w-full max-w-full mb-12"
                :class="{
                  [route.name || '']: true,
                }"
              >
                <component
                  :is="Component"
                  :key="`${locale}-${viewRoute.path}`"
                />
              </section>
            </transition>
          </router-view>
        </div>
      </div>
    </div>
    <AppModal />
  </div>
</template>
