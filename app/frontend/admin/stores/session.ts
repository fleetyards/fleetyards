import { formatISO, parseISO, differenceInMinutes } from "date-fns";
import { defineStore } from "pinia";
import { type AdminUser } from "@/services/fyAdminApi";
import { me as fetchMe, destroySession } from "@/services/fyAdminApi";

interface SessionState {
  authenticated: boolean;
  currentUser?: AdminUser;
  accessConfirmed?: string;
}

export const useSessionStore = defineStore("session", {
  state: (): SessionState => ({
    authenticated: false,
    currentUser: undefined,
    accessConfirmed: undefined,
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
    accessConfirmedDate(state) {
      if (!state.accessConfirmed) {
        return false;
      }

      const diff = differenceInMinutes(
        new Date(),
        parseISO(state.accessConfirmed),
      );

      return diff < 10;
    },
  },
  actions: {
    async fetchUserAndlogin() {
      await fetchMe().then((user) => {
        this.login(user);
      });
    },
    login(user: AdminUser) {
      this.authenticated = true;
      this.currentUser = user;
    },
    async logout() {
      await destroySession().finally(() => {
        this.authenticated = false;
        this.currentUser = undefined;
      });
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
    confirmAccess() {
      this.accessConfirmed = formatISO(new Date());
    },
    resetConfirmAccess() {
      this.accessConfirmed = undefined;
    },
  },
  persist: {
    pick: ["authenticated"],
  },
});
