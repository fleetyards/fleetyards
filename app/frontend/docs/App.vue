<template>
  <div
    id="docs"
    class="transition-all lg:transition-none flex flex-col min-h-screen"
  >
    <AppBackground />

    <div class="flex items-stretch">
      <transition name="fade" mode="out-in">
        <AppNavigationMobile v-if="mobile" />
      </transition>
      <transition name="fade" mode="out-in">
        <AppNavigation />
      </transition>
      <div
        class="flex flex-col flex-1 justify-between max-w-full h-full lg:pl-[300px]"
      >
        <div class="min-h-screen">
          <router-view v-slot="{ Component, route }">
            <transition name="fade" mode="out-in">
              <component
                :is="Component"
                :key="`${locale}-${route.path}`"
                class="transition-nav ease-[ease] duration-500 relative w-full max-w-full mb-12"
                :class="[
                  collapsed
                    ? 'left-0 right-auto'
                    : '-left-[300px] right-[300px]',
                ]"
              />
            </transition>
          </router-view>
        </div>

        <AppFooter />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import AppNavigation from "@/docs/components/core/AppNavigation/index.vue";
import AppNavigationMobile from "@/docs/components/core/AppNavigation/Mobile/index.vue";
import AppBackground from "@/docs/components/core/AppBackground/index.vue";
import { useAppStore } from "@/docs/stores/app";
import { useI18nStore } from "@/shared/stores/i18n";
import { storeToRefs } from "pinia";
import { useNavStore } from "@/docs/stores/nav";
import AppFooter from "@/docs/components/core/AppFooter/index.vue";
import { useNProgress } from "@/shared/composables/useNProgress";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

useNProgress();

useMetaInfo();

const navStore = useNavStore();

const { collapsed } = storeToRefs(navStore);

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

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
  name: "DocsApp",
};
</script>
