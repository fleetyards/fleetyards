import { defineStore } from "pinia";

interface Cookies {
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
    paths: ["infoVisible", "cookies"],
  },
});
