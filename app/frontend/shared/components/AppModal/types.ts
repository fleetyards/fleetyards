import type { Component } from "vue";

export type AppModalOptions = {
  component: () => Promise<Component>;
  title?: string;
  wide?: boolean;
  // Nearly the whole window, inset from its edges: for a workspace that needs
  // the room but should still read as a dialog over the page.
  large?: boolean;
  fixed?: boolean;
  fullscreen?: boolean;
  dirty?: boolean;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  props?: any;
};
