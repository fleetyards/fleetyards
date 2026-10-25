import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { type ItemMedia, type MediaFile } from "@/services/fyApi";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useGallery", () => ({
  useGallery: vi.fn(),
}));

import ItemViews from "./index.vue";

const file = (name: string): MediaFile => ({
  name,
  contentType: "image/webp",
  size: 1000,
  url: `https://example.test/${name}`,
  mediumUrl: `https://example.test/medium/${name}`,
  width: 1024,
  height: 512,
});

const mountViews = (media: ItemMedia) =>
  mount(ItemViews, {
    props: { media, name: "P4-AR Rifle" },
    global: {
      stubs: {
        MetricsCard: {
          template: "<section><slot /></section>",
        },
        LazyImage: {
          props: ["href"],
          template: '<a class="gallery-image" :href="href" />',
        },
      },
    },
  });

describe("ItemViews", () => {
  it("lists the views it has, angled first, each opening full size", () => {
    const wrapper = mountViews({
      topView: file("top.webp"),
      angledView: file("angled.webp"),
    });

    const links = wrapper.findAll(".gallery-image");

    expect(links.map((link) => link.attributes("href"))).toEqual([
      "https://example.test/angled.webp",
      "https://example.test/top.webp",
    ]);
  });

  it("renders nothing without views", () => {
    const wrapper = mountViews({});

    expect(wrapper.find("[data-test='item-views']").exists()).toBe(false);
  });
});
