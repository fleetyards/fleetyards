import type { TZoomData } from "@/@types/fleetchart";

export interface ShipListState {
  detailsVisible: boolean;
  filterVisible: boolean;
  fleetchartVisible: boolean;
  fleetchartZoomData?: TZoomData;
  fleetchartViewpoint: "side" | "top" | "angled";
  fleetchartLabels: boolean;
  fleetchartScreenHeight: "1x" | "1_5x" | "2x" | "3x" | "4x";
  fleetchartMode: "panzoom" | "classic";
  fleetchartScale: number;
  perPage: number;
}
