export interface SyncResultTile {
  key: string;
  value: number | string;
  label: string;
  // A second, smaller line: how many of the total are new.
  note?: string;
  // For a caller whose tests read the number on its own.
  valueTest?: string;
}
