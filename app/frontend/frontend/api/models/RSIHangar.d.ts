type TRSIHangarItemKind = "ship" | "component" | "skin";

type TRSIHangarItem = {
  id: string;
  name: string;
  customName?: string;
  type: TRSIHangarItemKind;
};
