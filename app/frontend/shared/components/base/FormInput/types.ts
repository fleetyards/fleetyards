export enum InputTypesEnum {
  TEXT = "text",
  NUMBER = "number",
  PASSWORD = "password",
  EMAIL = "email",
  URL = "url",
  COLOR = "color",
  DATE = "date",
  DATETIME_LOCAL = "datetime-local",
}

export enum InputSizesEnum {
  DEFAULT = "default",
  // Pairs with Btn's md, so an input sits flush next to a button in the page
  // header. FormTextarea carries its own copy of this enum; if a textarea ever
  // needs to sit in a header row, add it there too rather than diverging.
  MEDIUM = "medium",
  LARGE = "large",
}

export enum InputVariantsEnum {
  DEFAULT = "default",
  CLEAN = "clean",
}

export enum InputAlignmentsEnum {
  RIGHT = "right",
  LEFT = "left",
}
