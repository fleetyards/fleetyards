// A translated line whose numbers count in place: the translation is looked
// up with its placeholders left standing, and each is filled with a number
// that animates. `template` is for a line with no translation of its own, such
// as "+%{count}".
export interface SyncNumberTextValue {
  key?: string;
  template?: string;
  values: Record<string, number>;
}
