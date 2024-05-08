import { defineStore } from "pinia";
import { type AdminUser } from "@/services/fyAdminApi";

interface SessionState {
  authenticated: boolean;
  currentUser?: AdminUser;
}

export const useSessionStore = defineStore("session", {
  state: (): SessionState => ({
    authenticated: false,
    currentUser: undefined,
  }),
  getters: {
    isAuthenticated(state) {
      return state.authenticated;
    },
  },
  actions: {
    login() {
      this.authenticated = true;
    },
    async logout() {
      this.authenticated = false;
      this.currentUser = undefined;
    },
  },
  persist: {
    paths: ["authenticated"],
  },
});
