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
        <NavigationMobile v-if="mobile" />
      </transition>
      <transition name="fade" mode="out-in">
        <Navigation />
      </transition>
      <div class="main-wrapper">
        <div class="main-inner">
          <NavigationHeader />

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

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Getter, Mutation } from "vuex-class";
import Updates from "@/frontend/mixins/Updates";
import userCollection from "@/frontend/api/collections/User";
import versionCollection from "@/frontend/api/collections/Version";
import Navigation from "@/frontend/core/components/Navigation/index.vue";
import NavigationHeader from "@/frontend/core/components/Navigation/Header/index.vue";
import NavigationMobile from "@/frontend/core/components/Navigation/Mobile/index.vue";
import AppFooter from "@/frontend/core/components/AppFooter/index.vue";
import AppModal from "@/frontend/core/components/AppModal/index.vue";
import AppShoppingCart from "@/frontend/core/components/AppShoppingCart/index.vue";
import BackgroundImage from "@/frontend/core/components/BackgroundImage/index.vue";
import { requestPermission } from "@/frontend/lib/Noty";
import { useI18n } from "@/frontend/composables/useI18n";

const CHECK_VERSION_INTERVAL = 1800 * 1000; // 30 mins

const { I18n, availableLocales } = useI18n();

@Component<FrontendApp>({
  components: {
    BackgroundImage,
    Navigation,
    NavigationHeader,
    NavigationMobile,
    AppFooter,
    AppModal,
    AppShoppingCart,
  },
  mixins: [Updates],
})
export default class FrontendApp extends Vue {
  sessionRenewInterval: boolean = null;

  @Getter("mobile") mobile;

  @Getter("locale") locale;

  @Getter("navCollapsed", { namespace: "app" }) navCollapsed: boolean;

  @Getter("overlayVisible", { namespace: "app" }) overlayVisible: boolean;

  @Getter("isAuthenticated", { namespace: "session" }) isAuthenticated: boolean;

  @Getter("currentUser", { namespace: "session" }) currentUser: User;

  @Getter("cookies", { namespace: "cookies" }) cookies;

  @Getter("infoVisible", { namespace: "cookies" })
  cookiesInfoVisible: boolean;

  @Mutation("setLocale") setLocale;

  get ahoyAccepted() {
    return this.cookies.ahoy;
  }

  @Watch("navCollapsed")
  onNavCollapsedChange() {
    this.setNoScroll();
  }

  @Watch("overlayVisible")
  onOverlayVisibleChange() {
    this.setNoScroll();
  }

  @Watch("isAuthenticated")
  onAuthenticationChange() {
    if (this.isAuthenticated) {
      requestPermission();
      this.fetchCurrentUser();
    } else {
      if (this.sessionRenewInterval) {
        clearInterval(this.sessionRenewInterval);
      }

      if (this.$route.meta.needsAuthentication) {
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        this.$router.push({ name: "login" }).catch(() => {});
      }
    }
  }

  @Watch("$route")
  onRouteChange() {
    this.checkSessionReload();
    if (this.cookiesInfoVisible && this.$route.name !== "privacy-policy") {
      this.openPrivacySettings();
    } else if (
      this.cookiesInfoVisible &&
      this.$route.name === "privacy-policy"
    ) {
      this.$comlink.$emit("close-modal", true);
    }
    this.setupLocale();
  }

  @Watch("ahoyAccepted")
  onAhoyAcceptedChange() {
    if (this.ahoyAccepted) {
      this.$ahoy.trackView();
      // this.$ahoy.trackClicks()
      this.$ahoy.trackSubmits("form");
      this.$ahoy.trackChanges("input, textarea, select");
    } else {
      window.location.reload(true);
    }
  }

  @Watch("locale")
  onLocaleChange() {
    if (this.locale) {
      I18n.locale = this.locale;
    }
  }

  async created() {
    this.checkSessionReload();
    this.setNoScroll();
    this.checkMobile();

    if (this.isAuthenticated) {
      requestPermission();
      this.fetchCurrentUser();
    }

    if (this.ahoyAccepted) {
      this.$ahoy.trackView();
      // this.$ahoy.trackClicks()
      this.$ahoy.trackSubmits("form");
      this.$ahoy.trackChanges("input, textarea, select");
    }

    this.checkVersion();

    setInterval(() => {
      this.checkVersion();
    }, CHECK_VERSION_INTERVAL);

    this.$comlink.$on("open-privacy-settings", this.openPrivacySettings);

    window.addEventListener("resize", this.checkMobile);
    this.$comlink.$on("user-update", this.fetchCurrentUser);
    this.$comlink.$on("fleet-create", this.fetchCurrentUser);
    this.$comlink.$on("fleet-update", this.fetchCurrentUser);

    this.setupLocale();
  }

  beforeDestroy() {
    window.removeEventListener("resize", this.checkMobile);
    this.$comlink.$off("user-update");
    this.$comlink.$off("fleet-create");
    this.$comlink.$off("fleet-update");
  }

  setupLocale() {
    if (!this.locale && availableLocales.includes(navigator.language)) {
      this.setLocale(navigator.language);
    }

    if (this.locale) {
      I18n.locale = this.locale;
    }
  }

  openPrivacySettings(settings = false) {
    this.$comlink.$emit("open-modal", {
      component: () =>
        import("@/frontend/core/components/PrivacySettings/index.vue"),
      fixed: true,
      props: {
        settings,
      },
    });
  }

  checkMobile() {
    this.$store.commit("setMobile", document.documentElement.clientWidth < 992);
  }

  setNoScroll() {
    if (!this.navCollapsed) {
      document.body.classList.add("nav-visible");
    } else {
      document.body.classList.remove("nav-visible");
    }

    if (!this.navCollapsed || this.overlayVisible) {
      document.body.classList.add("no-scroll");
    } else {
      document.body.classList.remove("no-scroll");
    }
  }

  async checkSessionReload() {
    if (this.$route.query.reload_session) {
      await this.$store.dispatch("session/login");
    }
  }

  async fetchCurrentUser() {
    await this.$store.commit(
      "session/setCurrentUser",
      await userCollection.current()
    );
  }

  async checkVersion() {
    await this.$store.dispatch(
      "app/updateVersion",
      await versionCollection.current()
    );
  }
}
</script>
