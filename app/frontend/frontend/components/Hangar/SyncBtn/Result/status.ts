import type { SyncProcessStep } from "./types";

// A step still running is what the modal's bottom cap reports.
export const isSyncStepRunning = (steps: SyncProcessStep[]) =>
  steps.some((step) => step.status === "processing");

// A skipped step is one the extension could not run, not one that went wrong:
// the sync still counts as done.
export const isSyncStepDone = (step: SyncProcessStep) =>
  step.status === "success" || step.status === "skipped";
