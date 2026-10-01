import type { SyncProcessStep } from "./types";

// A step still running is what the modal's bottom cap reports.
export const isSyncStepRunning = (steps: SyncProcessStep[]) =>
  steps.some((step) => step.status === "processing");
