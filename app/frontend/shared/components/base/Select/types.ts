export enum BaseSelectSizesEnum {
  DEFAULT = "default",
  // 48px, to match Btn's md and FormInput's medium. FormInput carries its own copy of
  // this enum rather than sharing one; this follows that, so a size can be added to one
  // control without dragging the others into it.
  MEDIUM = "medium",
}

export enum BaseSelectVariantsEnum {
  DEFAULT = "default",
  /*
   * Sized and framed by the field it sits in, for a prefix or suffix slot -- the
   * logistics quantity fields use one for their unit picker.
   *
   * A native <select> was the obvious thing to put there and is the wrong thing:
   * it opens the platform's own dropdown, so the app would have two selects that
   * look and behave differently the moment either is opened. This is the same
   * control with its frame taken off.
   */
  AFFIX = "affix",
}
