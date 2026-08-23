// What the pill means. Colours the tint and the edge together, since a pill is
// a filled badge rather than a framed surface — the cap-carries-the-tone rule
// Panel follows does not apply to something this small.
export enum PillVariantsEnum {
  // The primary blue, which reads as "happening" rather than as quiet.
  DEFAULT = "default",
  // Grey. For a state that asks nothing of the reader.
  NEUTRAL = "neutral",
  SUCCESS = "success",
  WARNING = "warning",
  DANGER = "danger",
}

// A pill is inline by default; the block tags exist for the few places one
// stands alone in a column.
export enum PillTagsEnum {
  SPAN = "span",
  DIV = "div",
  P = "p",
}
