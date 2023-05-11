type TRSIHangarItemKind = "ship" | "component" | "skin" | "upgrade";

type TRSIHangarItem = {
  id: string;
  name: string;
  customName?: string;
  type: TRSIHangarItemKind;
};
