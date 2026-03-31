import { defineStore } from "pinia";

type SearchHistoryEntry = {
  search: string;
  createdAt: Date;
};

type SearchState = {
  history: SearchHistoryEntry[];
};

export const useSearchStore = defineStore("search", {
  state: (): SearchState => ({
    history: [],
  }),
  actions: {
    save(payload: SearchHistoryEntry) {
      this.history = this.history.filter(
        (item) => item.search !== payload.search,
      );

      if (this.history.length > 30) {
        this.history.pop();
      }

      this.history.unshift(payload);
    },
  },
  persist: true,
});
