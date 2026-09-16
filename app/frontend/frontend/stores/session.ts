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
        // A response that arrives after the session was cleared -- a 401 on a
        // parallel request, a sign out mid-flight -- must not put the user
        // back. `authenticated` is what everything else reads, so a
        // `currentUser` beside it saying otherwise is a state nothing recovers
        // from.
        if (!this.authenticated) {
          return;
        }

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
    // `currentUser` is persisted so a reload of a signed-in session renders the
    // account straight away rather than flashing a signed-out app. A session
    // that ended anywhere but through this store's own logout leaves it behind,
    // and a signed-out visitor then reads as that account -- on the login page
    // that is every OAuth button rendered connected, so disabled, with no way
    // back other than clearing site data.
    afterHydrate: ({ store }) => {
      if (!store.authenticated) {
        store.currentUser = undefined;
      }
    },
  },
});
