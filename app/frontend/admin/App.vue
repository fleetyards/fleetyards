<script lang="ts">
export default {
  name: "AdminApp",
};
</script>

<script lang="ts" setup>
import AppModal from "@/shared/components/AppModal/index.vue";
import BackgroundImage from "@/shared/components/BackgroundImage/index.vue";
import AdminNavigation from "@/admin/components/Navigation/index.vue";
import AppNavigationHeader from "@/shared/components/AppNavigation/Header/index.vue";
import AppNavigationMobile from "@/shared/components/AppNavigation/Mobile/index.vue";
import { useI18nStore } from "@/shared/stores/i18n";
import { useAppStore } from "@/admin/stores/app";
import { storeToRefs } from "pinia";
import { useNProgress } from "@/shared/composables/useNProgress";
import AppFooter from "@/shared/components/AppFooter/index.vue";
import AppEnvironment from "@/shared/components/AppEnvironment/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

useNProgress();
useMetaInfo({
  appTitle: t("title.defaultAdmin"),
});

const route = useRoute();

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

const appStore = useAppStore();

const mobile = useMobile();
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
    <BackgroundImage />

    <div class="flex items-stretch">
      <transition name="fade" mode="out-in">
        <AppNavigationMobile v-if="mobile" />
      </transition>
      <transition name="fade" mode="out-in">
        <AdminNavigation />
      </transition>
      <div class="flex flex-1 flex-col max-w-full h-full">
        <div class="min-h-screen">
          <AppNavigationHeader />
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
        <AppEnvironment :git-revision="appStore.gitRevision" />

        <AppFooter
          :revision="appStore.version"
          :codename="appStore.codename"
          :git-revision="appStore.gitRevision"
          :online="appStore.online"
        />
      </div>
    </div>
    <AppModal />
  </div>
</template>
