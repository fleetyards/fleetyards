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
  },
  persist: {
    paths: ["perPage"],
  },
});
