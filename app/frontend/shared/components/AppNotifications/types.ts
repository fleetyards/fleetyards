export enum MessageTypesEnum {
  SUCCESS = "success",
  INFO = "info",
  WARNING = "warning",
  ALERT = "alert",
}

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
};
