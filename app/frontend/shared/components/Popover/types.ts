export type PopoverPlacement = "top" | "bottom";

// How the open popover came up. A tap-opened one has no pointer resting on it
// to leave, so only a tap elsewhere, Escape or a scroll closes it.
export type PopoverTrigger = "hover" | "focus" | "tap";
