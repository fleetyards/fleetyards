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
  SYNC_STORE_CREDIT = "syncStoreCredit",
  IDENTIFY = "identify",
  VERIFY_WRITE = "verify-write",
  VERIFY_REMOVE = "verify-remove",
  ORG_VERIFY_WRITE = "org-verify-write",
  ORG_VERIFY_REMOVE = "org-verify-remove",
}

export type FleetyardsSyncSessionPayload = {
  handle: string;
};

// The store credit RSI lists for the account, in USD.
export type FleetyardsSyncStoreCreditPayload = {
  credit: number;
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
    | FleetyardsSyncStoreCreditPayload
    | FleetyardsSyncVerifyPayload;
};

export interface FleetyardsSyncEvent extends Event {
  data: {
    direction: FleetyardsSyncDirection;
    message: string;
  };
}
