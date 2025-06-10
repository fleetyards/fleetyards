import { formatISO, parseISO, differenceInMinutes } from "date-fns";
import { defineStore } from "pinia";
import { useHangarStore } from "./hangar";
import {
  type User,
  me as fetchMe,
  destroySession,
  hangar,
} from "@/services/fyApi";

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
        parseISO(state.accessConfirmed),
      );

      return diff < 10;
    },
  },
  actions: {
    async fetchUserAndLogin() {
      await fetchMe().then((user) => {
        this.login(user);
      });
    },
    login(user: User) {
      this.authenticated = true;
      this.currentUser = user;
    },
    async logout() {
      await destroySession().finally(() => {
        const hangarStore = useHangarStore();
        hangarStore.ships = [];

        this.$reset();
      });
    },
    confirmAccess() {
      this.accessConfirmed = formatISO(new Date());
    },
    resetConfirmAccess() {
      this.accessConfirmed = undefined;
    },
    hasAccessTo(resource: string) {
      return this.currentUser?.resourceAccess?.includes(resource) || false;
    },
  },
  persist: {
    pick: ["authenticated", "accessConfirmed"],
  },
});
