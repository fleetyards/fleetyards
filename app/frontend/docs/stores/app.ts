import { defineStore } from "pinia";

type AppState = {
  version: string;
  codename: string;
  gitRevision: string;
  online: boolean;
};

export const useAppStore = defineStore("app", {
  state: (): AppState => ({
    version: window.APP_VERSION,
    codename: window.APP_CODENAME,
    gitRevision: window.GIT_REVISION,
    online: true,
  }),
  getters: {
    isUpdateAvailable(state) {
      return state.version !== window.APP_VERSION;
    },
  },
  actions: {
    setOnlineStatus(payload: boolean) {
      this.online = payload;
    },
    updateVersion(payload: { version?: string; codename?: string } = {}) {
      if (payload && payload.version && this.version !== payload.version) {
        this.version = payload.version;
        if (payload.codename) {
          this.codename = payload.codename;
        }
      }
    },
  },
});
