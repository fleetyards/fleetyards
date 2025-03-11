import { defineStore } from "pinia";
import { type RouterLinkProps } from "vue-router";

type RedirectBackState = {
  backRoute?: RouterLinkProps["to"];
};

export const useRedirectBackStore = defineStore("redirectBack", {
  state: (): RedirectBackState => ({
    backRoute: undefined,
  }),
  actions: {
    setBackRoute(backRoute: RouterLinkProps["to"]) {
      this.backRoute = backRoute;
    },
  },
  persist: true,
});
