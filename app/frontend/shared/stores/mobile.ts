import { defineStore } from "pinia";

const mobileBreakpoint = 992;

export const isMobileWidth = () =>
  typeof document !== "undefined" &&
  document.documentElement.clientWidth < mobileBreakpoint;

type MobileState = {
  mobile: boolean;
};

export const useMobileStore = defineStore("mobile", {
  state: (): MobileState => ({
    mobile: isMobileWidth(),
  }),
});
