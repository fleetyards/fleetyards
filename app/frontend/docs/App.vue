<script lang="ts">
export default {
  name: "DocsApp",
};
</script>

<script lang="ts" setup>
import AppModal from "@/shared/components/AppModal/index.vue";
import AppNavigationHeader from "@/shared/components/AppNavigation/Header/index.vue";
import AppFooter from "@/shared/components/AppFooter/index.vue";
import AppEnvironment from "@/shared/components/AppEnvironment/index.vue";
import AppNotifications from "@/shared/components/AppNotifications/index.vue";
import BackgroundImage from "@/shared/components/BackgroundImage/index.vue";
import AppNavigation from "@/docs/components/Navigation/index.vue";
import AppNavigationMobile from "@/docs/components/Navigation/Mobile/index.vue";
import { useAppStore } from "@/docs/stores/app";
import { useI18nStore } from "@/shared/stores/i18n";
import { useMobile } from "@/shared/composables/useMobile";
import { storeToRefs } from "pinia";
import { useNavStore } from "@/shared/stores/nav";
import { useNProgress } from "@/shared/composables/useNProgress";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

useNProgress();

useMetaInfo({
  appTitle: t("title.defaultDocs"),
});

const route = useRoute();

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

const appStore = useAppStore();

const mobile = useMobile();

const navStore = useNavStore();

const { collapsed: navCollapsed } = storeToRefs(navStore);

watch(
  () => navCollapsed.value,
  () => {
    setNoScroll();
  },
);

onMounted(async () => {
  setNoScroll();
});

const setNoScroll = () => {
  if (!navCollapsed.value) {
    document.body.classList.add("nav-visible");
  } else {
    document.body.classList.remove("nav-visible");
  }

  if (!navCollapsed.value) {
    document.body.classList.add("no-scroll");
  } else {
    document.body.classList.remove("no-scroll");
  }
};
</script>

<template>
  <div
    :key="locale"
    :class="{
      [`page-${String(route.name)}`]: true,
    }"
    class="app-body"
  >
    <BackgroundImage />

    <div class="app-content">
      <transition name="fade" mode="out-in">
        <AppNavigationMobile v-if="mobile" />
      </transition>
      <transition name="fade" mode="out-in">
        <AppNavigation />
      </transition>
      <div class="main-wrapper">
        <div class="main-inner">
          <AppNavigationHeader />

          <router-view v-slot="{ Component, route: viewRoute }">
            <transition name="fade" mode="out-in">
              <section
                class="container main"
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

        <AppFooter
          :revision="appStore.version"
          :codename="appStore.codename"
          :git-revision="appStore.gitRevision"
          :online="appStore.online"
        />
      </div>
    </div>

    <AppModal />
    <AppNotifications />
    <AppEnvironment :git-revision="appStore.gitRevision" show-in-production />
  </div>
</template>
