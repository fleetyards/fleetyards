import { defineStore } from "pinia";
import { isNewerVersion } from "@/shared/utils/AppVersion";
import type {
  AppVersionAnnouncement,
  AppVersionPayload,
} from "@/shared/stores/types";

type AppState = {
  version: string;
  codename: string;
  gitRevision: string;
  announcement?: AppVersionAnnouncement;
  online: boolean;
};

export const useAppStore = defineStore("app", {
  state: (): AppState => ({
    version: window.APP_VERSION,
    codename: window.APP_CODENAME,
    gitRevision: window.GIT_REVISION,
    announcement: undefined,
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
    updateVersion(payload: AppVersionPayload = {}) {
      if (payload.version && isNewerVersion(payload.version, this.version)) {
        this.version = payload.version;
        if (payload.codename) {
          this.codename = payload.codename;
        }
      }
      this.announcement = payload.announcement;
    },
  },
});
