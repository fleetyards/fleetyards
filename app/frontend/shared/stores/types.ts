import type { Store } from "pinia";

export type AppVersionAnnouncement = {
  title: string;
  link: string;
  publishedAt: string;
};

export type AppVersionPayload = {
  version?: string;
  codename?: string;
  announcement?: AppVersionAnnouncement;
};

export interface FltYrdsStore extends Store {
  storeVersion?: string;
  updateVersion: (payload: AppVersionPayload) => void;
  resetAll?: (hard?: boolean) => void;
}
