// What an RSI pledge-page parser made of a page. Only RSI's own end-of-list
// markup is `END`; a page the parser no longer understands is `UNRECOGNISED`,
// and the sync has to stop on it rather than take it for the end.
export enum RsiPageStatus {
  PAGE = "page",
  END = "end",
  UNRECOGNISED = "unrecognised",
}
