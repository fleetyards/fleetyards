import { describe, expect, it } from "vitest";
import { isSyncStepRunning } from "./status";
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
