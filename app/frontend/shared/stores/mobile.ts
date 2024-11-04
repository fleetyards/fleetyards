import { defineStore } from "pinia";

type MobileState = {
  mobile: boolean;
};

export const useMobileStore = defineStore("mobile", {
  state: (): MobileState => ({
    mobile: false,
  }),
});
