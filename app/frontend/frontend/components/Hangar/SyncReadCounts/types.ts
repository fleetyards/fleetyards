export interface SyncReadCount {
  key: string;
  label: string;
  count: number;
  // A kind the run leaves out: still counted, so the steps agree, but marked.
  skipped?: boolean;
  dataTest?: string;
}
