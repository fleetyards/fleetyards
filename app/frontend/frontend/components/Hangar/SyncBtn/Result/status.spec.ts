import { describe, expect, it } from "vitest";
import { isSyncStepRunning, syncOutcomeMessage } from "./status";
import { HangarSyncOutcomeEnum } from "@/services/fyApi";
import type { SyncProcessStep } from "./types";

const steps = (...statuses: SyncProcessStep["status"][]): SyncProcessStep[] =>
  statuses.map((status, index) => ({ name: `step${index}`, status }));

describe("isSyncStepRunning", () => {
  it("is running while a step is processing", () => {
    expect(isSyncStepRunning(steps("success", "processing"))).toBe(true);
  });

  it("is not running before any step starts", () => {
    expect(isSyncStepRunning(steps("pending", "pending"))).toBe(false);
  });

  it("is not running once every step has ended, however it ended", () => {
    expect(isSyncStepRunning(steps("success", "success"))).toBe(false);
    expect(isSyncStepRunning(steps("success", "failure"))).toBe(false);
    expect(isSyncStepRunning(steps("success", "backendFailure"))).toBe(false);
  });
});

describe("syncOutcomeMessage", () => {
  it("says a run synced, and so did one from before outcomes", () => {
    expect(syncOutcomeMessage(HangarSyncOutcomeEnum.SYNCED)).toEqual({
      synced: true,
      key: "messages.syncExtension.success",
    });
    expect(syncOutcomeMessage(undefined).synced).toBe(true);
  });

  it("does not call a run that changed nothing a sync", () => {
    expect(syncOutcomeMessage(HangarSyncOutcomeEnum.NOTHING_TO_SYNC)).toEqual({
      synced: false,
      key: "messages.syncExtension.nothingToSync",
    });
    expect(
      syncOutcomeMessage(HangarSyncOutcomeEnum.ONLY_SKIPPED_ITEMS),
    ).toEqual({
      synced: false,
      key: "messages.syncExtension.onlySkippedItems",
    });
  });
});
