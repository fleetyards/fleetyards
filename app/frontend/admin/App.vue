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
import AdminNavigationMobile from "@/admin/components/Navigation/Mobile/index.vue";
import { useI18nStore } from "@/shared/stores/i18n";
import { useAppStore } from "@/admin/stores/app";
import { storeToRefs } from "pinia";
import { useNProgress } from "@/shared/composables/useNProgress";
import AppFooter from "@/shared/components/AppFooter/index.vue";
import AppEnvironment from "@/shared/components/AppEnvironment/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";
import { useApiClient } from "@/admin/composables/useApiClient";
import { useSessionStore } from "@/admin/stores/session";
import { useNavStore } from "@/shared/stores/nav";
import { useOverlayStore } from "@/shared/stores/overlay";
import { useComlink } from "@/shared/composables/useComlink";
import { useNoty } from "@/shared/composables/useNoty";
import { useImportUpdates } from "@/admin/composables/useImportUpdates";

const { t } = useI18n();

useNProgress();
useMetaInfo({
  appTitle: t("title.defaultAdmin"),
});

useImportUpdates("ModelsImport");

const route = useRoute();

const comlink = useComlink();

const i18nStore = useI18nStore();

const { locale } = storeToRefs(i18nStore);

const appStore = useAppStore();

const mobile = useMobile();

const navStore = useNavStore();

const { collapsed: navCollapsed } = storeToRefs(navStore);

const overlayStore = useOverlayStore();

const { visible: overlayVisible } = storeToRefs(overlayStore);

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const { adminUsers: adminUsersService } = useApiClient();

const { requestBrowserPermission } = useNoty();

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

      fetchCurrentUser();
    } else if (route.meta.needsAuthentication) {
      router.push({ name: "login" });
    }
  },
);

watch(
  () => route.name,
  () => {
    checkSessionReload();

    // setupLocale();
  },
);

onMounted(async () => {
  checkSessionReload();
  setNoScroll();

  if (isAuthenticated.value) {
    requestBrowserPermission();

    fetchCurrentUser();
  }

  // checkVersion();

  // setInterval(() => {
  //   checkVersion();
  // }, CHECK_VERSION_INTERVAL);

  comlink.on("user-update", fetchCurrentUser);

  // setupLocale();
});

onUnmounted(() => {
  comlink.off("user-update");
});

const fetchCurrentUser = async () => {
  try {
    const user = await adminUsersService.me();
    sessionStore.currentUser = user;
  } catch (error) {
    console.error(error);
  }
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
        <AdminNavigationMobile v-if="mobile" />
      </transition>
      <transition name="fade" mode="out-in">
        <AdminNavigation />
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
