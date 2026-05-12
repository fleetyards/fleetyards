import { defineStore } from "pinia";

type ContextSource = "list" | "calendar-month" | "calendar-week";

type FleetEventListContext = {
  source: ContextSource;
  slugs: string[];
};

interface FleetEventListContextState {
  byFleet: Record<string, FleetEventListContext>;
}

export const useFleetEventListContextStore = defineStore(
  "fleetEventListContext",
  {
    state: (): FleetEventListContextState => ({
      byFleet: {},
    }),
    getters: {
      slugsFor:
        (state) =>
        (fleetSlug: string): string[] =>
          state.byFleet[fleetSlug]?.slugs ?? [],
    },
    actions: {
      setContext(fleetSlug: string, source: ContextSource, slugs: string[]) {
        this.byFleet[fleetSlug] = { source, slugs };
      },
      clear(fleetSlug: string) {
        delete this.byFleet[fleetSlug];
      },
    },
    persist: {
      storage: sessionStorage,
    },
  },
);
