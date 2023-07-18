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
      <div class="flex flex-col justify-between max-w-full h-full flex-[1_1]">
        <div class="min-h-screen">
          <transition name="fade" mode="out-in">
            <router-view
              :key="route.path"
              class="transition-nav ease-[ease] duration-500 relative w-full max-w-full mb-12"
              :class="[
                collapsed ? 'left-0 right-auto' : '-left-[300px] right-[300px]',
              ]"
            />
          </transition>
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
import { useRoute } from "vue-router/composables";
import { useAppStore } from "@/docs/stores/app";
import { storeToRefs } from "pinia";
import { useNavStore } from "@/docs/stores/nav";
import AppFooter from "@/docs/components/core/AppFooter/index.vue";

const navStore = useNavStore();

const { collapsed } = storeToRefs(navStore);

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

const route = useRoute();

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
