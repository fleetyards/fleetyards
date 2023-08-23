import { defineStore } from "pinia";
import { useMobile } from "@/shared/composables/useMobile";

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
      const mobile = useMobile();

      return state.slim && !mobile.value;
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
