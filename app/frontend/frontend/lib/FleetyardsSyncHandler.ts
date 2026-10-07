export enum FleetyardsSyncDirection {
  TO = "fy-sync",
  FROM = "fy",
}

export enum FleetyardsSyncAction {
  HEALTH = "health",
  SYNC = "sync",
  SYNC_BUYBACK = "syncBuyback",
  SYNC_BUYBACK_DETAIL = "syncBuybackDetail",
  SYNC_BUYBACK_PRICING = "syncBuybackPricing",
  IDENTIFY = "identify",
  VERIFY_WRITE = "verify-write",
  VERIFY_REMOVE = "verify-remove",
}

export type FleetyardsSyncSessionPayload = {
  handle: string;
};

export interface FleetyardsSyncVerifyPayload {
  handle: string;
  changed?: boolean;
}

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
  // The pledge a buy-back detail page belongs to.
  id?: string;
  payload?:
    | string
    | FleetyardsSyncSessionPayload
    | FleetyardsSyncHealthPayload
    | FleetyardsSyncVerifyPayload;
};

export interface FleetyardsSyncEvent extends Event {
  data: {
    direction: FleetyardsSyncDirection;
    message: string;
  };
}
