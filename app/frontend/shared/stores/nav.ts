import { defineStore } from "pinia";
import { useMobileStore } from "@/shared/stores/mobile";

interface NavStoreState {
  collapsed: boolean;
  slim: boolean;
}

export const useNavStore = defineStore("nav", {
  state: (): NavStoreState => ({
    collapsed: true,
    slim: false,
  }),
  getters: {
    slimNavigation(state) {
      const mobileStore = useMobileStore();

      return state.slim && !mobileStore.mobile;
    },
  },
  actions: {
    toggle() {
      this.collapsed = !this.collapsed;
    },
    toggleSlim() {
      this.slim = !this.slim;
    },
    open() {
      this.collapsed = false;
    },
    close() {
      this.collapsed = true;
    },
  },
  persist: {
    paths: ["slim"],
  },
});
