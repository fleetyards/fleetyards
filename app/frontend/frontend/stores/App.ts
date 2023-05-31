import { defineStore } from "pinia";

import { useCookiesStore } from "./Cookies";
import { useFiltersStore } from "./Filters";
import { useFleetStore } from "./Fleet";
import { useHangarStore } from "./Hangar";
import { useModelsStore } from "./Models";
import { usePublicFleetStore } from "./PublicFleet";
import { usePublicHangarStore } from "./PublicHangar";
import { usePublicWishlistStore } from "./PublicWishlist";
import { useSearchStore } from "./Search";
import { useSessionStore } from "./Session";
import { useShopStore } from "./Shop";
import { useShoppingCartStore } from "./ShoppingCart";
import { useShopsStore } from "./Shops";
import { useStationsStore } from "./Stations";
import { useWishlistStore } from "./Wishlist";

interface AppState {
  version: string;
  codename: string;
  gitRevision: string;
  navCollapsed: boolean;
  navSlim: boolean;
  overlayVisible: boolean;
  locale: string;
  mobile: boolean;
  storeVersion: string | null;
  online: boolean;
}

export const useAppStore = defineStore("App", {
  state: (): AppState => ({
    version: window.APP_VERSION,
    codename: window.APP_CODENAME,
    gitRevision: window.GIT_REVISION,
    navCollapsed: true,
    navSlim: false,
    overlayVisible: false,
    locale: "en",
    mobile: false,
    storeVersion: null,
    online: true,
  }),
  getters: {
    slimNavigation(state) {
      return state.navSlim && !state.mobile;
    },
    isUpdateAvailable(state) {
      return state.version !== window.APP_VERSION;
    },
  },
  actions: {
    resetAll(hard = false) {
      const sessionStore = useSessionStore();
      const cookiesStore = useCookiesStore();
      const fleetStore = useFleetStore();
      const publicFleetStore = usePublicFleetStore();
      const hangarStore = useHangarStore();
      const publicHangarStore = usePublicHangarStore();
      const modelsStore = useModelsStore();
      const searchStore = useSearchStore();
      const shopStore = useShopStore();
      const shoppingCartStore = useShoppingCartStore();
      const shopsStore = useShopsStore();
      const stationsStore = useStationsStore();
      const wishlistStore = useWishlistStore();
      const publicWishlistStore = usePublicWishlistStore();
      const filtersStore = useFiltersStore();

      this.$reset();

      if (hard) {
        sessionStore.$reset();
        cookiesStore.$reset();
      }

      fleetStore.$reset();
      publicFleetStore.$reset();
      hangarStore.$reset();
      publicHangarStore.$reset();
      modelsStore.$reset();
      searchStore.$reset();
      shopStore.$reset();
      shoppingCartStore.$reset();
      shopsStore.$reset();
      stationsStore.$reset();
      wishlistStore.$reset();
      publicWishlistStore.$reset();
      filtersStore.$reset();
    },
    setStoreVersion(newVersion: string) {
      this.storeVersion = newVersion;
    },
    setLocale(locale: string) {
      this.locale = locale;
    },
    setMobile(payload: boolean) {
      this.mobile = payload;
    },
    setOnlineStatus(payload: boolean) {
      this.online = payload;
    },
    updateVersion(payload: { version?: string; codename?: string } = {}) {
      if (payload && payload.version && this.version !== payload.version) {
        this.version = payload.version;
        if (payload.codename) {
          this.codename = payload.codename;
        }
      }
    },
    showOverlay() {
      this.overlayVisible = true;
    },
    hideOverlay() {
      this.overlayVisible = false;
    },
    toggleNav() {
      this.navCollapsed = !this.navCollapsed;
    },
    toggleSlimNav() {
      this.navSlim = !this.navSlim;
    },
    openNav() {
      this.navCollapsed = false;
    },
    closeNav() {
      this.navCollapsed = true;
    },
  },
  persist: {
    paths: ["navSlim", "storeVersion"],
  },
});
