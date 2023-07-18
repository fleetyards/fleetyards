import { defineStore } from "pinia";

type NavState = {
  collapsed: boolean;
  visible: boolean;
};

export const useNavStore = defineStore("nav", {
  state: (): NavState => ({
    collapsed: true,
    visible: true,
  }),
  actions: {
    toggle() {
      this.collapsed = !this.collapsed;
    },
  },
});
