<template>
  <div
    id="app"
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

          <transition name="fade" mode="out-in">
            <router-view :key="$route.path" class="main" />
          </transition>
        </div>

        <AppFooter />
      </div>
    </div>

    <AppShoppingCart />

    <AppModal />
  </div>
</template>

<script lang="ts" setup>
import userCollection from "@/frontend/api/collections/User";
import versionCollection from "@/frontend/api/collections/Version";
import AppNavigation from "@/frontend/core/components/AppNavigation/index.vue";
import AppNavigationHeader from "@/frontend/core/components/AppNavigation/Header/index.vue";
import AppNavigationMobile from "@/frontend/core/components/AppNavigation/Mobile/index.vue";
import AppFooter from "@/frontend/core/components/AppFooter/index.vue";
import AppModal from "@/shared/components/AppModal/index.vue";
import AppShoppingCart from "@/frontend/core/components/AppShoppingCart/index.vue";
import BackgroundImage from "@/shared/components/BackgroundImage/index.vue";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useUpdates } from "@/frontend/composables/useUpdates";
import { useAppStore } from "@/frontend/stores/app";
import { useOverlayStore } from "@/shared/stores/overlay";
import { useI18nStore } from "@/shared/stores/i18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useCookiesStore } from "@/frontend/stores/cookies";
import { storeToRefs } from "pinia";
import { useRoute } from "vue-router";
import { useMobile } from "@/shared/composables/useMobile";
import { useComlink } from "@/shared/composables/useComlink";
import { useAhoy } from "@/frontend/composables/useAhoy";

const mobile = useMobile();

useUpdates();

useAhoy();

const appStore = useAppStore();

const { navCollapsed } = storeToRefs(appStore);

const overlayStore = useOverlayStore();

const { visible: overlayVisible } = storeToRefs(overlayStore);

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const cookiesStore = useCookiesStore();

const { infoVisible } = storeToRefs(cookiesStore);

const CHECK_VERSION_INTERVAL = 1800 * 1000; // 30 mins

const { t, availableLocales } = useI18n();

useMetaInfo(t);

const { requestBrowserPermission } = useNoty(t);

watch(
  () => navCollapsed.value,
  () => {
    setNoScroll();
  },
);

watch(
  () => overlayVisible.value,
  () => {
    setNoScroll();
  },
);

watch(
  () => isAuthenticated.value,
  () => {
    if (isAuthenticated) {
      requestBrowserPermission();

      fetchCurrentUser();
    }
  },
);

const route = useRoute();

const comlink = useComlink();

watch(
  () => route.name,
  () => {
    checkSessionReload();

    if (infoVisible.value && route.name !== "privacy-policy") {
      openPrivacySettings();
    } else if (infoVisible.value && route.name === "privacy-policy") {
      comlink.emit("close-modal", true);
    }

    setupLocale();
  },
);

const checkStoreVersion = () => {
  if (appStore.storeVersion !== window.STORE_VERSION) {
    console.info("Updating Store Version and resetting Store");

    appStore.$reset();
    appStore.storeVersion = window.STORE_VERSION;
  }
};

onBeforeMount(() => {
  checkStoreVersion();
});

onMounted(async () => {
  checkSessionReload();
  setNoScroll();

  if (isAuthenticated.value) {
    requestBrowserPermission();

    fetchCurrentUser();
  }

  checkVersion();

  setInterval(() => {
    checkVersion();
  }, CHECK_VERSION_INTERVAL);

  comlink.on("open-privacy-settings", openPrivacySettings);
  comlink.on("user-update", fetchCurrentUser);
  comlink.on("fleet-create", fetchCurrentUser);
  comlink.on("fleet-update", fetchCurrentUser);

  setupLocale();
});

onUnmounted(() => {
  comlink.off("user-update");
  comlink.off("fleet-create");
  comlink.off("fleet-update");
});

const setupLocale = () => {
  if (!locale.value && availableLocales().includes(navigator.language)) {
    i18nStore.locale = navigator.language;
  }
};

const openPrivacySettings = (settings = false) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/core/components/PrivacySettings/index.vue"),
    fixed: true,
    props: {
      settings,
    },
  });
};

const setNoScroll = () => {
  if (!navCollapsed.value) {
    document.body.classList.add("nav-visible");
  } else {
    document.body.classList.remove("nav-visible");
  }

  if (!navCollapsed.value || overlayVisible.value) {
    document.body.classList.add("no-scroll");
  } else {
    document.body.classList.remove("no-scroll");
  }
};

const checkSessionReload = async () => {
  if (route.query.reload_session) {
    sessionStore.login();
  }
};

const fetchCurrentUser = async () => {
  const response = await userCollection.current();
  if (response.data) {
    sessionStore.currentUser = response.data;
  }
};

const checkVersion = async () => {
  const response = await versionCollection.current();

  if (response) {
    appStore.updateVersion(response);
  }
};
</script>

<script lang="ts">
export default {
  name: "FrontendApp",
};
</script>
