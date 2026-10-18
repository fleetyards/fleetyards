import type { SyncProgress } from "@/frontend/components/Hangar/SyncProgressBar/types";

export type SyncStepStatus = "pending" | "active" | "done" | "failed";

export interface SyncStep {
  key: string;
  label: string;
  detail?: string;
  // A line under the bar.
  caption?: string;
  status: SyncStepStatus;
  // A fraction where the step knows its total, or only that it is working.
  progress?: SyncProgress | "indeterminate";
}
