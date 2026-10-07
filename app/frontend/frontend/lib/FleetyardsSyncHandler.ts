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

// What an extension can do. Released versions before buy-backs answer the
// health check without a payload at all.
export type FleetyardsSyncHealthPayload = {
  version?: string;
  actions?: string[];
};

export type FleetyardsSyncMessage = {
  action: FleetyardsSyncAction;
  code?: number;
  error?: string;
  payload?: string | FleetyardsSyncSessionPayload | FleetyardsSyncHealthPayload;
};

export interface FleetyardsSyncEvent extends Event {
  data: {
    direction: FleetyardsSyncDirection;
    message: string;
  };
}
