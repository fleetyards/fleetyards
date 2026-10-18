export type SyncStepStatus = "pending" | "active" | "done" | "failed";

export type SyncStep = {
  key: string;
  label: string;
  detail?: string;
  status: SyncStepStatus;
  // A fraction where the step knows its total, or only that it is working.
  progress?: { value: number; max: number } | "indeterminate";
};
