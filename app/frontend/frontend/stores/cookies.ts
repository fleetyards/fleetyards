import { defineStore } from "pinia";

interface CookiesState {
  cookies: {
    youtube: boolean;
  };
}

export const useCookiesStore = defineStore("cookies", {
  state: (): CookiesState => ({
    cookies: {
      youtube: false,
    },
  }),
  getters: {
    youtubeAccepted(): boolean {
      return this.cookies.youtube;
    },
  },
  actions: {
    acceptYoutube() {
      this.cookies.youtube = true;
    },
  },
  persist: {
    pick: ["cookies"],
  },
});
