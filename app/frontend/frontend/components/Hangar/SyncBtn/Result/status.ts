import type { SyncProcessStep } from "./types";
import { HangarSyncOutcomeEnum } from "@/services/fyApi";

// A step still running is what the modal's bottom cap reports.
export const isSyncStepRunning = (steps: SyncProcessStep[]) =>
  steps.some((step) => step.status === "processing");

// The toast for a finished run, whether the modal or the cable listener
// reports it. Runs from before the sync reported an outcome always synced.
export const syncOutcomeMessage = (outcome?: string) => {
  if (outcome === HangarSyncOutcomeEnum.NOTHING_TO_SYNC) {
    return { synced: false, key: "messages.syncExtension.nothingToSync" };
  }

  if (outcome === HangarSyncOutcomeEnum.ONLY_SKIPPED_ITEMS) {
    return { synced: false, key: "messages.syncExtension.onlySkippedItems" };
  }

  return { synced: true, key: "messages.syncExtension.success" };
};
