import { type MediaFile } from "@/services/fyApi";

export enum ViewImageSizeEnum {
  SOURCE = "source",
  SMALL = "small",
  MEDIUM = "medium",
  LARGE = "large",
  XLARGE = "xlarge",
}

export const viewImageSizeMapping: Record<
  ViewImageSizeEnum,
  keyof Omit<
    MediaFile,
    "width" | "height" | "name" | "contentType" | "size" | "uploadedAt"
  >
> = {
  [ViewImageSizeEnum.SOURCE]: "url",
  [ViewImageSizeEnum.SMALL]: "smallUrl",
  [ViewImageSizeEnum.MEDIUM]: "mediumUrl",
  [ViewImageSizeEnum.LARGE]: "largeUrl",
  [ViewImageSizeEnum.XLARGE]: "xlargeUrl",
};
