import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type ModelModule } from "@/services/fyApi";
import PanelBgImage from "@/shared/components/base/Panel/BgImage/index.vue";
import Component from "./index.vue";

const file = (url: string) => ({
  name: "image.webp",
  contentType: "image/webp",
  size: 1,
  url,
  mediumUrl: url,
});

const buildModule = (overrides: Partial<ModelModule> = {}): ModelModule => ({
  id: "module-1",
  name: "Cargo Module",
  slug: "cargo-module",
  availability: { boughtAt: [], soldAt: [] },
  media: {},
  createdAt: "2026-11-17T00:00:00Z",
  updatedAt: "2026-11-17T00:00:00Z",
  ...overrides,
});

const backgroundOf = async (module: ModelModule) => {
  const wrapper = await mountWithDefaults(Component, { props: { module } });

  return wrapper.getComponent(PanelBgImage).props("image");
};

describe("ModulePanel", () => {
  // jsdom has no IntersectionObserver for the lazy background to hand it to.
  beforeEach(() => {
    vi.stubGlobal(
      "IntersectionObserver",
      class {
        observe() {}
        unobserve() {}
        disconnect() {}
      },
    );
  });

  it("shows the store image", async () => {
    const image = await backgroundOf(
      buildModule({
        media: { storeImage: file("https://example.com/store.webp") },
        angledView: file("https://example.com/angled.webp"),
      }),
    );

    expect(image).toBe("https://example.com/store.webp");
  });

  it("falls back to the module's render without a store image", async () => {
    const image = await backgroundOf(
      buildModule({ angledView: file("https://example.com/angled.webp") }),
    );

    expect(image).toBe("https://example.com/angled.webp");
  });
});
