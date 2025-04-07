<script lang="ts">
export default {
  name: "FrontendApp",
};
</script>

<script lang="ts" setup>
import FrontendNavigation from "@/frontend/components/Navigation/index.vue";
import AppNavigationHeader from "@/shared/components/AppNavigation/Header/index.vue";
import FrontendNavigationMobile from "@/frontend/components/Navigation/Mobile/index.vue";
import AppFooter from "@/shared/components/AppFooter/index.vue";
import AppEnvironment from "@/shared/components/AppEnvironment/index.vue";
import AppModal from "@/shared/components/AppModal/index.vue";
import AppConfirm from "@/shared/components/AppConfirm/index.vue";
import AppNotifications from "@/shared/components/AppNotifications/index.vue";
import SecurePage from "@/frontend/components/core/SecurePage/index.vue";
import BackgroundImage from "@/shared/components/BackgroundImage/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useUpdates } from "@/frontend/composables/useUpdates";
import { useAppStore } from "@/frontend/stores/app";
import { useNavStore } from "@/shared/stores/nav";
import { useOverlayStore } from "@/shared/stores/overlay";
import { useI18nStore } from "@/shared/stores/i18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useCookiesStore } from "@/frontend/stores/cookies";
import { storeToRefs } from "pinia";
import { useRoute } from "vue-router";
import { useMobile } from "@/shared/composables/useMobile";
import { useComlink } from "@/shared/composables/useComlink";
import { useAhoy } from "@/frontend/composables/useAhoy";
import { useMe as useMeQuery } from "@/services/fyApi";
import { useVersion as useVersionQuery } from "@/services/fyApi";
import { useNProgress } from "@/shared/composables/useNProgress";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useAxiosInterceptors } from "@/frontend/composables/useAxiosInterceptors";
import { useCheckStoreVersion } from "@/shared/composables/useCheckStoreVersion";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

useWebpCheck(true);

useAxiosInterceptors();

useNProgress();

const mobile = useMobile();

useUpdates();

useAhoy();

const { requestBrowserPermission } = useAppNotifications();

const appStore = useAppStore();

const navStore = useNavStore();

const { collapsed: navCollapsed } = storeToRefs(navStore);

const overlayStore = useOverlayStore();

const { visible: overlayVisible } = storeToRefs(overlayStore);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const cookiesStore = useCookiesStore();

const { infoVisible } = storeToRefs(cookiesStore);

const CHECK_VERSION_INTERVAL = 1800 * 1000; // 30 mins

const { t, availableLocales, currentLocale } = useI18n();

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

const router = useRouter();

watch(
  () => isAuthenticated.value,
  () => {
    if (isAuthenticated.value) {
      requestBrowserPermission();
    } else if (route.meta.needsAuthentication) {
      router.push({ name: "login" });
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

useCheckStoreVersion(appStore);

onMounted(async () => {
  checkSessionReload();
  setNoScroll();

  if (isAuthenticated.value) {
    requestBrowserPermission();
  }

  setInterval(() => {
    refetchVersion();
  }, CHECK_VERSION_INTERVAL);

  comlink.on("open-privacy-settings", openPrivacySettings);
  comlink.on("user-update", refetchCurrentUser);
  comlink.on("fleet-create", refetchCurrentUser);
  comlink.on("fleet-update", refetchCurrentUser);

  setupLocale();
});

onUnmounted(() => {
  comlink.off("open-privacy-settings");
  comlink.off("user-update");
  comlink.off("fleet-create");
  comlink.off("fleet-update");
});

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

const setupLocale = () => {
  if (!locale.value && availableLocales().includes(navigator.language)) {
    i18nStore.locale = navigator.language;
  }
};

const openPrivacySettings = (settings = false) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/core/PrivacySettings/index.vue"),
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

const { data: user, refetch: refetchCurrentUser } = useMeQuery({
  query: {
    enabled: isAuthenticated,
  },
});

watch(
  () => user.value,
  () => {
    if (user.value) {
      sessionStore.currentUser = user.value;
    }
  },
);

const { data: version, refetch: refetchVersion } = useVersionQuery();

watch(
  () => version.value,
  () => {
    if (version.value) {
      appStore.updateVersion(version.value);
    }
  },
);

const localeMapping = {
  de: "Deutsch",
  en: "English",
  es: "Español",
  fr: "Français",
  it: "Italiano",
  zh: "中文",
  "zh-CN": "中文 (简体)",
  "zh-TW": "中文 (繁體)",
};

const locales = computed(() => {
  return availableLocales() as (keyof typeof localeMapping)[];
});

const activeLocale = (locale: string) => {
  return (
    locale === currentLocale() ||
    (!locale.includes("zh") && locale === currentLocale().split("-")[0])
  );
};

const setLocale = (locale: string) => {
  i18nStore.locale = locale;
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
        <FrontendNavigationMobile v-if="mobile" />
      </transition>
      <transition name="fade" mode="out-in">
        <FrontendNavigation />
      </transition>
      <div class="main-wrapper">
        <div class="main-inner">
          <AppNavigationHeader />

          <router-view v-slot="{ Component, route: viewRoute }">
            <transition name="fade" mode="out-in">
              <SecurePage
                v-if="
                  viewRoute.meta.needsSecurityConfirm &&
                  !sessionStore.accessConfirmedDate
                "
              />
              <section
                v-else
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
          :codename="appStore.codename"
          :version="appStore.version"
          :git-revision="appStore.gitRevision"
          :online="appStore.online"
        >
          <a
            v-tooltip="'Roberts Space Industries'"
            href="https://robertsspaceindustries.com/"
            target="_blank"
            rel="noopener"
          >
            RSI
          </a>
          |
          <router-link :to="{ name: 'privacy-policy' }">
            {{ t("nav.privacyPolicy") }}
          </router-link>
          |
          <router-link :to="{ name: 'impressum' }">
            {{ t("nav.impressum") }}
          </router-link>
          |
          <a href="https://api.fleetyards.net" target="_blank" rel="noopener">
            {{ t("nav.api") }}
          </a>
          |
          <BtnDropdown
            :text-inline="true"
            :inline="true"
            :size="BtnSizesEnum.SMALL"
            :variant="BtnVariantsEnum.LINK"
            :expand-top="true"
          >
            <template #label>
              <i class="fad fa-language" /> {{ currentLocale() }}
            </template>
            <Btn
              v-for="availableLocale in locales"
              :key="`locale-${availableLocale}`"
              :size="BtnSizesEnum.SMALL"
              :active="activeLocale(availableLocale)"
              @click="setLocale(availableLocale)"
            >
              {{ localeMapping[availableLocale] }} - {{ availableLocale }}
            </Btn>
          </BtnDropdown>
        </AppFooter>
      </div>
    </div>

    <AppConfirm />
    <AppModal />
    <AppNotifications />
    <AppEnvironment :git-revision="appStore.gitRevision" />
  </div>
</template>
