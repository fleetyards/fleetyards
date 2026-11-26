export type TapKind = "mount" | "builtIn" | "door";

export type Pointed = Partial<Record<TapKind, string>>;

// A click acts at once. A finger has no hover to read the card by first, so
// its first tap only points, and a second tap on what is pointed acts.
export const tapActs = (
  touch: boolean,
  kind: TapKind,
  id: string,
  pointed: Pointed,
): boolean => !touch || pointed[kind] === id;
