import { defineStore } from "pinia";

type PaginationStoreType = {
  perPage: {
    [key: string]: number | string | undefined;
  };
};

export const usePaginationStore = defineStore("pagination", {
  state: (): PaginationStoreType => ({
    perPage: {},
  }),
  getters: {
    findByKey: (store) => (key: string) => store.perPage[key],
  },
  actions: {
    setBykey(key: string, value: string | number) {
      this.perPage[key] = value;
    },
    removeByKey(key: string) {
      delete this.perPage[key];
    },
  },
  persist: {
    // A new key when the offered sizes change: a size saved from the old set
    // (30 on a card grid) would leave a short row on every page and match no
    // step in the dropdown.
    key: "pagination-v2",
    pick: ["perPage"],
  },
});
