import { defineStore } from "pinia";

type AppState = {
  mobile: boolean;
};

export const useAppStore = defineStore("app", {
  state: (): AppState => ({
    mobile: false,
  }),
});
