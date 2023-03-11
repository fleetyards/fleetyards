import { defineStore } from "pinia";

type HistoryItem = {
  search: string;
};

interface SearchState {
  history: HistoryItem[];
}

export const useSearchStore = defineStore("Search", {
  state: (): SearchState => ({
    history: [],
  }),
  actions: {
    save(payload) {
      // eslint-disable-next-line no-param-reassign
      this.history = this.history.filter(
        (item) => item.search !== payload.search
      );

      if (this.history.length >= 20) {
        this.history.pop();
      }

      this.history.unshift(payload);
    },
  },
  persist: true,
});
