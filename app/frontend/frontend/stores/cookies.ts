import { defineStore } from "pinia";

interface CookiesState {
  cookies: {
    youtube: boolean;
    tracking: boolean;
  };
}

export const useCookiesStore = defineStore("cookies", {
  state: (): CookiesState => ({
    cookies: {
      youtube: false,
      // Analytics run on legitimate interest, so guests start opted in and can
      // object here. Signed-in users are governed by their account setting.
      tracking: true,
    },
  }),
  getters: {
    youtubeAccepted(): boolean {
      return this.cookies.youtube;
    },
    trackingAccepted(): boolean {
      return this.cookies.tracking;
    },
  },
  actions: {
    acceptYoutube() {
      this.cookies.youtube = true;
    },
    setTracking(value: boolean) {
      this.cookies.tracking = value;
    },
  },
  persist: {
    pick: ["cookies"],
  },
});
