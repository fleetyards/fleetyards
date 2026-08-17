export enum BtnTypesEnum {
  BUTTON = "button",
  RESET = "reset",
  SUBMIT = "submit",
}

export enum BtnSizesEnum {
  XS = "xs",
  SM = "sm",
  MD = "md",
  LG = "lg",
}

// How much chrome the button carries. Kept separate from tone so that a quiet
// destructive action is expressible, which the old single `variant` enum -
// default | transparent | link | danger - could not do.
export enum BtnVariantsEnum {
  SOLID = "solid",
  GHOST = "ghost",
  BARE = "bare",
}

export enum BtnTonesEnum {
  NEUTRAL = "neutral",
  DANGER = "danger",
}
