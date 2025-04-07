import { defineStore } from "pinia";

type WebpState = {
  supported: boolean;
};

export const useWebpStore = defineStore("webp", {
  state: (): WebpState => ({
    supported: true,
  }),
});
