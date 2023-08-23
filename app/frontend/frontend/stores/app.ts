import { defineStore } from "pinia";

import { useCookiesStore } from "./cookies";
import { useFiltersStore } from "@/shared/stores/filters";
import { useOverlayStore } from "@/shared/stores/overlay";
import { useFleetStore } from "./fleet";
import { useHangarStore } from "./hangar";
// import { useModelsStore } from "./Models";
// import { usePublicFleetStore } from "./PublicFleet";
// import { usePublicHangarStore } from "./PublicHangar";
// import { usePublicWishlistStore } from "./PublicWishlist";
// import { useSearchStore } from "./Search";
import { useSessionStore } from "./session";
import { useNavStore } from "./nav";
import { useShoppingCartStore } from "./shoppingCart";
// import { useShopStore } from "./Shop";
// import { useShopsStore } from "./Shops";
// import { useStationsStore } from "./Stations";
// import { useWishlistStore } from "./Wishlist";

interface AppState {
  version: string;
  codename: string;
  gitRevision: string;
  storeVersion: string | null;
  online: boolean;
}

export const useAppStore = defineStore("app", {
  state: (): AppState => ({
    version: window.APP_VERSION,
    codename: window.APP_CODENAME,
    gitRevision: window.GIT_REVISION,
    storeVersion: null,
    online: true,
  }),
  getters: {
    isUpdateAvailable(state) {
      return state.version !== window.APP_VERSION;
    },
  },
  actions: {
    resetAll(hard = false) {
      const sessionStore = useSessionStore();
      const cookiesStore = useCookiesStore();
      const fleetStore = useFleetStore();
      const navStore = useNavStore();
      const shoppingCartStore = useShoppingCartStore();
      // const publicFleetStore = usePublicFleetStore();
      const hangarStore = useHangarStore();
      // const publicHangarStore = usePublicHangarStore();
      // const modelsStore = useModelsStore();
      // const searchStore = useSearchStore();
      // const shopStore = useShopStore();
      // const shopsStore = useShopsStore();
      // const stationsStore = useStationsStore();
      // const wishlistStore = useWishlistStore();
      // const publicWishlistStore = usePublicWishlistStore();
      const filtersStore = useFiltersStore();
      const overlayStore = useOverlayStore();

      this.$reset();

      if (hard) {
        sessionStore.$reset();
        cookiesStore.$reset();
        navStore.$reset();
      }

      fleetStore.$reset();
      // publicFleetStore.$reset();
      hangarStore.$reset();
      // publicHangarStore.$reset();
      // modelsStore.$reset();
      // searchStore.$reset();
      // shopStore.$reset();
      shoppingCartStore.$reset();
      // shopsStore.$reset();
      // stationsStore.$reset();
      // wishlistStore.$reset();
      // publicWishlistStore.$reset();
      filtersStore.$reset();
      overlayStore.$reset();
    },
    setStoreVersion(newVersion: string) {
      this.storeVersion = newVersion;
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
  },
  persist: {
    paths: ["storeVersion"],
  },
});
