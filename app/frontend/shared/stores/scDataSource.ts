import { defineStore } from "pinia";

// Declared here rather than imported from the generated client on purpose: the
// axios client asks this store which source a request carries, and importing the
// client's types back into the store would close that circle.
export type ScDataSourceOption = {
  environment: string;
  version: string;
  default: boolean;
};

interface ScDataSourceState {
  // Undefined means "whatever the server calls default", which is what a reader
  // who has never touched the switch gets.
  environment?: string;
  available: ScDataSourceOption[];
}

export const useScDataSourceStore = defineStore("scDataSource", {
  state: (): ScDataSourceState => ({
    environment: undefined,
    available: [],
  }),
  getters: {
    // The one the server would pick on its own, which is what the switch shows
    // as selected until somebody chooses otherwise.
    defaultSource(state): ScDataSourceOption | undefined {
      return state.available.find((source) => source.default);
    },

    selected(state): ScDataSourceOption | undefined {
      if (!state.environment) return this.defaultSource;

      return state.available.find(
        (source) => source.environment === state.environment,
      );
    },

    // Only worth a switch when there is something to switch to.
    hasChoice(state): boolean {
      return state.available.length > 1;
    },

    // What the axios client puts on a request. Nothing for the default, so a
    // reader who has not chosen sends exactly what it always sent.
    requestParam(): string | undefined {
      const selected = this.selected as ScDataSourceOption | undefined;

      if (!selected || selected.default) return undefined;

      return selected.environment;
    },
  },
  actions: {
    setAvailable(available: ScDataSourceOption[]) {
      this.available = available;

      // A source that has gone away -- an environment retired, or one that has
      // not been loaded since -- must not stay selected, or every request would
      // carry a parameter the server ignores while the switch claims otherwise.
      if (
        this.environment &&
        !available.some((source) => source.environment === this.environment)
      ) {
        this.environment = undefined;
      }
    },

    select(environment?: string) {
      this.environment = environment;
    },
  },
  persist: {
    // The available list comes from the server on every boot; only the choice is
    // worth keeping.
    pick: ["environment"],
  },
});
