export interface SyncResultTile {
  key: string;
  // A number counts up in place; text, such as "12 / 37", is shown as it is.
  value: number | string;
  label: string;
  // A second, smaller line: how many of the total are new.
  note?: string;
  // A kind the run leaves out: still counted, but marked.
  skipped?: boolean;
  // For callers whose tests read the label or the number on its own.
  labelTest?: string;
  valueTest?: string;
}
