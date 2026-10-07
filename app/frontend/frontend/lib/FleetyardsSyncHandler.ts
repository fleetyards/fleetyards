export enum FleetyardsSyncDirection {
  TO = "fy-sync",
  FROM = "fy",
}

export enum FleetyardsSyncAction {
  HEALTH = "health",
  SYNC = "sync",
  SYNC_BUYBACK = "syncBuyback",
  IDENTIFY = "identify",
}

export type FleetyardsSyncSessionPayload = {
  handle: string;
};

export type FleetyardsSyncMessage = {
  action: FleetyardsSyncAction;
  code?: number;
  error?: string;
  payload?: string | FleetyardsSyncSessionPayload;
};

export interface FleetyardsSyncEvent extends Event {
  data: {
    direction: FleetyardsSyncDirection;
    message: string;
  };
}
