// How much chrome the surface carries.
export enum PanelVariantsEnum {
  // 2px edge, radius 16, end-caps, shadow.
  DEFAULT = "default",
  // 1px edge, radius 12, no caps. For repeated cards in narrow columns, where
  // the full frame reads as noise — the metrics-card--slim treatment.
  SLIM = "slim",
}

// What the surface means. Colours the edge only; there is no filled counterpart,
// see the panel-redesign plan's D9.
export enum PanelTonesEnum {
  NEUTRAL = "neutral",
  PRIMARY = "primary",
  SUCCESS = "success",
  ERROR = "error",
  HIGHLIGHT = "highlight",
}

export enum PanelAlignmentsEnum {
  LEFT = "left",
  RIGHT = "right",
}

// Shared by Panel's background image, PanelImage and PanelBody. Previously three
// near-identical declarations, one of which (PanelBody's) was a copy of
// PanelImage's type under a misleading name.
export enum PanelRoundedEnum {
  ALL = "all",
  LEFT = "left",
  RIGHT = "right",
  TOP = "top",
  BOTTOM = "bottom",
}
