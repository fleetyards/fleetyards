import type { Component } from "vue";

export type AppModalOptions = {
  component: () => Promise<Component>;
  title?: string;
  wide?: boolean;
  fixed?: boolean;
  fullscreen?: boolean;
  dirty?: boolean;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  props?: any;
};
