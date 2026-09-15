import { formatISO, parseISO, differenceInMinutes } from "date-fns";
import { defineStore } from "pinia";
import { useHangarStore } from "./hangar";
import { queryClient } from "@/frontend/plugins/QueryClient";
import {
  type User,
  me as fetchMe,
  destroySession,
  getMySupporterClaimKeyQueryKey,
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

      return diff < 28;
    },
  },
  actions: {
    async fetchUserAndLogin() {
      await fetchMe().then((user) => {
        this.login(user);
      });
    },
    async refreshUser() {
      await fetchMe().then((user) => {
        this.currentUser = user;
      });
    },
    login(user: User) {
      this.authenticated = true;
      this.currentUser = user;
    },
    clearSession() {
      const hangarStore = useHangarStore();
      hangarStore.ships = [];

      // A disabled query still serves whatever is cached, so the supporter
      // claim key would survive the logout and greet the next person here.
      queryClient.removeQueries({
        queryKey: getMySupporterClaimKeyQueryKey(),
      });

      this.$reset();
    },
    async logout() {
      this.clearSession();

      await destroySession().catch(() => {});
    },
    confirmAccess() {
      this.accessConfirmed = formatISO(new Date());
    },
    resetConfirmAccess() {
      this.accessConfirmed = undefined;
    },
    hasAccessTo(resource: string) {
      return (
        (this.currentUser?.resourceAccess as string[] | undefined)?.includes(
          resource,
        ) || false
      );
    },
  },
  persist: {
    pick: ["authenticated", "accessConfirmed", "currentUser"],
  },
});
