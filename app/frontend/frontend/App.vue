<template>
  <div
    id="app"
    :key="locale"
    :class="{
      [`page-${$route.name}`]: true,
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
import { onBeforeUnmount, watch } from "vue";
import { useRoute, useRouter } from "vue-router/composables";
import { storeToRefs } from "pinia";
import { useSessionStore } from "@/frontend/stores/Session";
import { useCookiesStore } from "@/frontend/stores/Cookies";
import userCollection from "@/frontend/api/collections/User";
import versionCollection from "@/frontend/api/collections/Version";
import { requestPermission } from "@/frontend/lib/Noty";
import AppNavigation from "@/frontend/core/components/AppNavigation/index.vue";
import AppNavigationHeader from "@/frontend/core/components/AppNavigation/Header/index.vue";
import AppNavigationMobile from "@/frontend/core/components/AppNavigation/Mobile/index.vue";
import AppFooter from "@/frontend/core/components/AppFooter/index.vue";
import AppModal from "@/frontend/core/components/AppModal/index.vue";
import AppShoppingCart from "@/frontend/core/components/AppShoppingCart/index.vue";
import BackgroundImage from "@/frontend/core/components/BackgroundImage/index.vue";
import { useComlink } from "@/frontend/composables/useComlink";
import { useAhoy } from "@/frontend/composables/useAhoy";
import { useUpdates } from "@/frontend/composables/useUpdates";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { useI18n } from "@/frontend/composables/useI18n";
import { useAppStore } from "@/frontend/stores/App";

useMetaInfo();

useAhoy();

useUpdates();

useAhoy();

useUpdates();

const CHECK_VERSION_INTERVAL = 1800 * 1000; // 30 mins

const { I18n, availableLocales } = useI18n();

const appStore = useAppStore();

const { mobile, locale } = storeToRefs(appStore);

const sessionStore = useSessionStore();

const cookiesStore = useCookiesStore();

const route = useRoute();

const checkSessionReload = () => {
  if (route.query.reload_session) {
    sessionStore.login();
  }
};

checkSessionReload();

const checkMobile = () => {
  appStore.mobile = document.documentElement.clientWidth < 992;
};

checkMobile();

const fetchCurrentUser = async () => {
  const response = await userCollection.current();

  if (response.data) {
    sessionStore.currentUser = response.data;
  }
};

if (sessionStore.isAuthenticated) {
  requestPermission();
  fetchCurrentUser();
}

const checkVersion = async () => {
  const version = await versionCollection.current();

  if (version) {
    appStore.updateVersion(version);
  }
};

onMounted(() => {
  checkVersion();
});

setInterval(() => {
  checkVersion();
}, CHECK_VERSION_INTERVAL);

const comlink = useComlink();

const openPrivacySettings = (settings = false) => {
  comlink.$emit("open-modal", {
    component: () =>
      import("@/frontend/core/components/PrivacySettings/index.vue"),
    fixed: true,
    props: {
      settings,
    },
  });
};

comlink.$on("open-privacy-settings", openPrivacySettings);

window.addEventListener("resize", checkMobile);
comlink.$on("user-update", fetchCurrentUser);
comlink.$on("fleet-create", fetchCurrentUser);
comlink.$on("fleet-update", fetchCurrentUser);

onBeforeUnmount(() => {
  window.removeEventListener("resize", checkMobile);
  comlink.$off("user-update");
  comlink.$off("fleet-create");
  comlink.$off("fleet-update");
});

watch(
  () => locale.value,
  () => {
    if (locale.value) {
      I18n.locale = locale.value;
    }
  }
);

watch(
  () => route,
  () => {
    checkSessionReload();
    if (cookiesStore.infoVisible && route.name !== "privacy-policy") {
      openPrivacySettings();
    } else if (cookiesStore.infoVisible && route.name === "privacy-policy") {
      comlink.$emit("close-modal", true);
    }
    setupLocale();
  },
  { deep: true }
);

const setupLocale = () => {
  if (!locale.value && availableLocales.includes(navigator.language)) {
    appStore.setLocale(navigator.language);
  }

  if (locale.value) {
    I18n.locale = locale.value;
  }
};

setupLocale();

const router = useRouter();

watch(
  () => sessionStore.isAuthenticated,
  () => {
    if (sessionStore.isAuthenticated) {
      requestPermission();
      fetchCurrentUser();
    } else if (route.meta?.needsAuthentication) {
      router.push({ name: "login" }).catch(() => {
        // ignore
      });
    }
  }
);
</script>

<script lang="ts">
export default {
  name: "AppComponent",
};
</script>
