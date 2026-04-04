import type { Component } from "vue";

export type OffCanvasOptions = {
  component: () => Promise<Component>;
  title?: string;
  side?: "left" | "right";
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  props?: any;
};
