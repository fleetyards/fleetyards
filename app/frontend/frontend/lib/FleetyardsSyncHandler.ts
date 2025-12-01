import { differenceInSeconds } from "date-fns";

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

export type FleetyardsSyncRequest = {
  direction: FleetyardsSyncDirection;
  message: FleetyardsSyncMessage; // JSON.stringify of FleetyardsSyncMessage
};

export interface FleetyardsSyncEvent extends Event {
  data: {
    direction: FleetyardsSyncDirection;
    message: string;
  };
}

class FleetyardsSyncHandler {
  private startTime: Date;

  private postCount: number;

  private maxPerMinute: number;

  constructor(maxPerMinute = 50) {
    this.startTime = new Date();
    this.postCount = 0;
    this.maxPerMinute = maxPerMinute;
  }

  async postMessage(data: FleetyardsSyncRequest) {
    const now = new Date();
    const elapsedSeconds = differenceInSeconds(now, this.startTime);

    // Reset counter if more than 60 seconds have passed
    if (elapsedSeconds >= 60) {
      this.startTime = now;
      this.postCount = 0;
    }

    // Calculate allowed messages based on elapsed time
    const allowedMessages = Math.floor(
      (elapsedSeconds / 60) * this.maxPerMinute,
    );

    if (this.postCount < allowedMessages || elapsedSeconds < 1) {
      this.postCount += 1;

      window.postMessage({
        ...data,
        message: JSON.stringify(data.message),
      });
    } else {
      setTimeout(() => {
        this.postMessage(data);
      }, 500);
    }
  }
}

export default FleetyardsSyncHandler;
