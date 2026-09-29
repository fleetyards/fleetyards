// What the notice means. Colours the edge, the caps and the icon together
// rather than only the caps like Panel, over a fill that is the same for all.
export enum AlertVariantsEnum {
  // Grey. A plain hint that asks nothing of the reader.
  NEUTRAL = "neutral",
  INFO = "info",
  SUCCESS = "success",
  WARNING = "warning",
  DANGER = "danger",
}

export enum AlertSizesEnum {
  DEFAULT = "default",
  // For tables, modals and narrow columns.
  COMPACT = "compact",
}
