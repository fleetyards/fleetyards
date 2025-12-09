export enum FleetyardsSyncDirection {
  TO = "fy-sync",
  FROM = "fy",
}

export enum FleetyardsSyncAction {
  SYNC = "sync",
  IDENTIFY = "identify",
}

export type FleetyardsSyncSessionPayload = {
  handle: string;
};

export type FleetyardsSyncMessage = {
  action: FleetyardsSyncAction;
  code?: number;
  payload?: string | FleetyardsSyncSessionPayload;
};

export interface FleetyardsSyncEvent extends Event {
  data: {
    direction: FleetyardsSyncDirection;
    message: string;
  };
}
