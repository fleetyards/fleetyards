// Three states, not two booleans: a chip is never both included and excluded,
// and the filter rows cycle neutral -> included -> excluded -> neutral. A binary
// consumer simply never reaches EXCLUDED.
export enum ChipStatesEnum {
  NEUTRAL = "neutral",
  INCLUDED = "included",
  EXCLUDED = "excluded",
}
