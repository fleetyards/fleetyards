import { formatISO, parseISO, differenceInMinutes } from "date-fns";
import { defineStore } from "pinia";
import { useHangarStore } from "./hangar";
import { queryClient } from "@/frontend/plugins/QueryClient";
import {
  type User,
  me as fetchMe,
  destroySession,
  getMySupporterClaimKeyQueryKey,
  getHangarAllInventoryStockQueryKey,
  getMyFleetsQueryKey,
} from "@/services/fyApi";

interface SessionState {
  authenticated: boolean;
  currentUser?: User;
  accessConfirmed?: string;
}

// Identifies the session a request was sent under, so a response can tell
// whether the session that asked for it is still the one here. Deliberately not
// store state: `$reset` would roll it back, and the session after a clear would
// then carry the same number as the one before it.
let sessionEpoch = 0;

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
      const epoch = sessionEpoch;

      await fetchMe().then((user) => {
        // Whatever session this was sent under may be gone by now: a 401 on a
        // parallel request cleared it, or somebody signed out and back in. The
        // first leaves `currentUser` next to `authenticated: false`, a state
        // nothing recovers from; the second would hand the account now signed
        // in the profile, connections and access of the one before it.
        if (epoch !== sessionEpoch) {
          return;
        }

        this.currentUser = user;
      });
    },
    login(user: User) {
      sessionEpoch += 1;

      this.authenticated = true;
      this.currentUser = user;
    },
    clearSession() {
      sessionEpoch += 1;

      const hangarStore = useHangarStore();
      hangarStore.ships = [];

      // A disabled query still serves whatever is cached, so the supporter
      // claim key would survive the logout and greet the next person here.
      queryClient.removeQueries({
        queryKey: getMySupporterClaimKeyQueryKey(),
      });

      // The same for what a blueprint page reads: the stock panel is disabled
      // when signed out rather than absent, and the catalogue is public, so
      // the cache would show the previous reader's hangar to whoever opens a
      // recipe next in the same tab.
      queryClient.removeQueries({
        queryKey: getHangarAllInventoryStockQueryKey(),
      });
      queryClient.removeQueries({ queryKey: getMyFleetsQueryKey() });

      // Fleet stock keys its slug in the middle, so a prefix cannot reach it.
      queryClient.removeQueries({
        predicate: (query) =>
          query.queryKey[0] === "fleets" &&
          query.queryKey[2] === "inventory-stock",
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
