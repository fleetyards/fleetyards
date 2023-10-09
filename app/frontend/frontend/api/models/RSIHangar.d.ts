type TRSIHangarItemKind = "ship" | "component" | "skin" | "upgrade";

type TRSIHangarItem = {
  id: string;
  name: string;
  image?: string;
  customName?: string;
  type: TRSIHangarItemKind;
};
