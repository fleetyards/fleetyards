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
    isSuperAdmin(state) {
      return state.currentUser?.superAdmin || false;
    },
    isAuthenticated(state) {
      return state.authenticated;
    },
    resourceAccess(state) {
      return state.currentUser?.resourceAccess || [];
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
    hasAccessTo(resource?: string) {
      if (!resource || resource === "all") {
        return true;
      }

      return (
        this.currentUser?.resourceAccess?.includes(resource) ||
        this.isSuperAdmin ||
        false
      );
    },
  },
  persist: {
    paths: ["authenticated"],
  },
});
