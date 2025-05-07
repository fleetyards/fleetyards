import { defineStore } from "pinia";

type OverlayState = {
  visible: boolean;
};

export const useOverlayStore = defineStore("overlay", {
  state: (): OverlayState => ({
    visible: false,
  }),
  actions: {
    show() {
      this.visible = true;
    },
    hide() {
      this.visible = false;
    },
  },
});
