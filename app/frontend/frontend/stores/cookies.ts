import { defineStore } from "pinia";

export interface Cookies {
  ahoy: boolean;
  youtube: boolean;
}

interface CookiesState {
  infoVisible: boolean;
  cookies: Cookies;
}

export const useCookiesStore = defineStore("cookies", {
  state: (): CookiesState => ({
    infoVisible: true,
    cookies: {
      ahoy: false,
      youtube: false,
    },
  }),
  getters: {
    ahoyAccepted(): boolean {
      return this.cookies.ahoy;
    },
    youtubeAccepted(): boolean {
      return this.cookies.youtube;
    },
  },
  actions: {
    hideInfo() {
      this.infoVisible = false;
    },
    updateAcceptedCookies(payload: Cookies) {
      this.cookies = payload;
    },
  },
  persist: {
    pick: ["infoVisible", "cookies"],
  },
});
