export interface SyncCount {
  key: string;
  // A number counts up in place; text is shown as it is.
  value: number | string;
  label: string;
  // A second, quieter note after the label: how many of the total are new.
  note?: string;
  // A kind the run leaves out: still counted, but marked.
  skipped?: boolean;
  // The last sync's figure for this row: the row gets a bar that fills toward
  // it, and says how far the run ended from it once final.
  reference?: number;
  final?: boolean;
  // For callers whose tests read the label or the number on its own.
  labelTest?: string;
  valueTest?: string;
}
