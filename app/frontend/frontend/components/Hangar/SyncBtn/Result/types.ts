export type SyncProcessStepName = "fetchHangar" | "submitData";

export type SyncProcessStepStatus =
  | "pending"
  | "processing"
  | "success"
  | "failure"
  | "backendFailure";

export type SyncProcessStep = {
  name: SyncProcessStepName | string;
  status: SyncProcessStepStatus;
};
