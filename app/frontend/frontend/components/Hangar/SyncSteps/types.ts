import type { SyncProgress } from "@/frontend/components/Hangar/SyncProgressBar/types";
import type { SyncNumberTextValue } from "@/frontend/components/Hangar/SyncNumberText/types";

export type SyncStepStatus = "pending" | "active" | "done" | "failed";

export interface SyncStep {
  key: string;
  label: string;
  // Plain text, or a line whose numbers count in place.
  detail?: string | SyncNumberTextValue;
  // A line under the bar.
  caption?: string | SyncNumberTextValue;
  status: SyncStepStatus;
  // A fraction where the step knows its total, or only that it is working.
  progress?: SyncProgress | "indeterminate";
}
