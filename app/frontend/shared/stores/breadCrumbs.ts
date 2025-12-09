import { defineStore } from "pinia";

type BreadCrumbState = {
  crumbs: Record<string, string>;
};

export const useBreadCrumbsStore = defineStore("breadCrumbs", {
  state: (): BreadCrumbState => ({
    crumbs: {},
  }),
  actions: {
    setCrumbs(key: string, path: string) {
      this.crumbs[key] = path;
    },
  },
  persist: true,
});
