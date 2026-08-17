export enum FilterGroupSizesEnum {
  DEFAULT = "default",
  // 48px, to match Btn's md and FormInput's medium. FormInput carries its own copy of
  // this enum rather than sharing one; this follows that, so a size can be added to one
  // control without dragging the others into it.
  MEDIUM = "medium",
}
