export enum MessageTypesEnum {
  SUCCESS = "success",
  INFO = "info",
  WARNING = "warning",
  ALERT = "alert",
}

import { type RouteLocationRaw } from "vue-router";

export type AppNotification = {
  id: string;
  type: MessageTypesEnum;
  visible: boolean;
  persist: boolean;
  text?: string;
  component?: () => Promise<Component>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  componentProps?: any;
  timeout?: number | false;
  background?: boolean;
  icon?: string;
  // Where clicking the message takes you, on top of dismissing it.
  to?: RouteLocationRaw;
};
