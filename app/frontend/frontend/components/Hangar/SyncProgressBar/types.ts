export interface SyncProgress {
  value: number;
  max: number;
  // A figure to measure the value against, such as the last sync's: past it,
  // the bar shows the excess beyond a mark; once final, a value short of it
  // shows the gap.
  reference?: number;
  final?: boolean;
}
