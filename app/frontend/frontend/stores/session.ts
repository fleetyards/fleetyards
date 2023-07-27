import { formatISO, parseISO, differenceInMinutes } from "date-fns";
import { defineStore } from "pinia";

import { useHangarStore } from "./hangar";

interface SessionState {
  authenticated: boolean;
  currentUser?: User;
  accessConfirmed?: string;
}

export const useSessionStore = defineStore("session", {
  state: (): SessionState => ({
    authenticated: false,
    currentUser: undefined,
    accessConfirmed: undefined,
  }),
  getters: {
    isAuthenticated(state) {
      return state.authenticated;
    },
    accessConfirmedDate(state) {
      if (!state.accessConfirmed) {
        return false;
      }

      const diff = differenceInMinutes(
        new Date(),
        parseISO(state.accessConfirmed)
      );

      return diff < 10;
    },
  },
  actions: {
    login() {
      this.authenticated = true;
    },
    async logout() {
      const hangarStore = useHangarStore();

      this.authenticated = false;
      hangarStore.ships = [];
      this.currentUser = undefined;
    },
    confirmAccess() {
      this.accessConfirmed = formatISO(new Date());
    },
    resetConfirmAccess() {
      this.accessConfirmed = undefined;
    },
  },
  persist: {
    paths: ["authenticated", "accessConfirmed"],
  },
});
