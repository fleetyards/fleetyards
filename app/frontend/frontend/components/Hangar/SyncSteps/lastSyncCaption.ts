import type { SyncNumberTextValue } from "@/frontend/components/Hangar/SyncNumberText/types";

// A reading step's line against what the last sync read: how far along while
// it reads, then by how much the run ended up above or below it.
export const lastSyncCaption = (
  count: number,
  last: number,
  done: boolean,
): SyncNumberTextValue => {
  const difference = count - last;

  if (!done && difference <= 0) {
    return {
      key: "labels.syncExtension.lastSync.reading",
      values: { count, total: last },
    };
  }

  if (difference > 0) {
    return {
      key: "labels.syncExtension.lastSync.more",
      values: { count: difference },
    };
  }

  if (difference < 0) {
    return {
      key: "labels.syncExtension.lastSync.fewer",
      values: { count: -difference },
    };
  }

  return { key: "labels.syncExtension.lastSync.same", values: {} };
};
