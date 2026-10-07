export type SyncProcessStepName =
  "fetchHangar" | "fetchBuybacks" | "submitData";

export type SyncProcessStepStatus =
  | "pending"
  | "processing"
  | "success"
  | "skipped"
  | "failure"
  | "backendFailure";

export type SyncProcessStep = {
  name: SyncProcessStepName | string;
  status: SyncProcessStepStatus;
};
