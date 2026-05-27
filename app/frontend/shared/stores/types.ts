import type { Store } from "pinia";

export interface FltYrdsStore extends Store {
  storeVersion?: string;
  updateVersion: (payload: { version?: string; codename?: string }) => void;
}
