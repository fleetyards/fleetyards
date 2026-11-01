import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { type ItemMedia, type MediaFile } from "@/services/fyApi";

const state = vi.hoisted(() => ({
  route: { name: "component-viewer", query: {} as Record<string, string> },
  emit: vi.fn(),
  listeners: {} as Record<string, () => void>,
  replace: vi.fn(),
}));

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () => state.route,
  useRouter: () => ({ replace: state.replace }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({
    emit: state.emit,
    on: (event: string, listener: () => void) => {
      state.listeners[event] = listener;
      return () => delete state.listeners[event];
    },
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

import ItemHoloViewer from "./index.vue";

const file = (name: string): MediaFile => ({
  name,
  contentType: "model/gltf-binary",
  size: 1000,
  url: `https://example.test/${name}`,
});

const backRoute = { name: "component", params: { slug: "storm" } };

const holos = { holo: file("holo.glb"), holoTextured: file("textured.glb") };

const mountViewer = (media: ItemMedia) =>
  mount(ItemHoloViewer, { props: { name: "Storm", media, backRoute } });

const opened = () => state.emit.mock.calls[0]?.[1].props;

describe("ItemHoloViewer", () => {
  beforeEach(() => {
    state.route = { name: "component-viewer", query: {} };
    state.emit.mockClear();
    state.replace.mockClear();
    state.listeners = {};
  });

  it("opens the item's holo full screen", () => {
    mountViewer(holos);

    expect(state.emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ fullscreen: true }),
    );
    expect(opened()).toEqual({ media: holos });
  });

  it("goes back to the item however it closes", () => {
    mountViewer(holos);

    state.listeners["modal-closed"]();

    expect(state.replace).toHaveBeenCalledWith({
      ...backRoute,
      query: undefined,
    });
  });

  it("stays put when the modal closes because the page was left", () => {
    mountViewer(holos);
    state.route.name = "component";

    state.listeners["modal-closed"]();

    expect(state.replace).not.toHaveBeenCalled();
  });

  it("goes back to the item without a holo to show", () => {
    mountViewer({});

    expect(state.emit).not.toHaveBeenCalled();
    expect(state.replace).toHaveBeenCalledWith(backRoute);
  });
});
