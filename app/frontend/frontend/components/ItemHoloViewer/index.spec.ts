import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { type ItemMedia, type MediaFile } from "@/services/fyApi";

const state = vi.hoisted(() => ({
  query: {} as Record<string, string>,
  emit: vi.fn(),
  replace: vi.fn(),
  updateMetaInfo: vi.fn(),
}));

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<typeof import("vue-router")>()),
  useRoute: () => ({ query: state.query }),
  useRouter: () => ({ replace: state.replace }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: state.emit }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: state.updateMetaInfo }),
}));

import ItemHoloViewer from "./index.vue";

const file = (name: string): MediaFile => ({
  name,
  contentType: "model/gltf-binary",
  size: 1000,
  url: `https://example.test/${name}`,
});

const backRoute = { name: "component", params: { slug: "storm" } };

const mountViewer = (media: ItemMedia) =>
  mount(ItemHoloViewer, { props: { name: "Storm", media, backRoute } });

const opened = () => state.emit.mock.calls[0]?.[1].props;

describe("ItemHoloViewer", () => {
  beforeEach(() => {
    state.query = {};
    state.emit.mockClear();
    state.replace.mockClear();
  });

  it("opens the item's holo full screen, closing back to the item", () => {
    const media = {
      holo: file("holo.glb"),
      holoTextured: file("textured.glb"),
    };

    mountViewer(media);

    expect(state.emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ fullscreen: true }),
    );
    expect(opened()).toEqual({ media, textured: false, backRoute });
  });

  it("opens on the textured holo when the link asks for it", () => {
    state.query = { textured: "1" };

    mountViewer({ holo: file("holo.glb"), holoTextured: file("textured.glb") });

    expect(opened()).toEqual(expect.objectContaining({ textured: true }));
  });

  it("goes back to the item without a holo to show", () => {
    mountViewer({});

    expect(state.emit).not.toHaveBeenCalled();
    expect(state.replace).toHaveBeenCalledWith(backRoute);
  });
});
