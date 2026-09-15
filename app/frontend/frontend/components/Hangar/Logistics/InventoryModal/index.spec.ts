import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required, min } from "@vee-validate/rules";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { inventoryDefaultImage } from "@/frontend/composables/useInventoryImage";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";
import Component from "./index.vue";

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: () => () => undefined }),
}));

// The file field's holo branch pulls in three.js, which will not resolve under
// vitest -- and none of this is about holos.
vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  default: { name: "HoloViewer", template: "<div />" },
}));

// The form's name field carries vee-validate rule names. Without them
// registered every mount throws "No such validator" as an unhandled error,
// which fails the file even when every assertion passed.
//
// And the field draws its picture through LazyImage, which jsdom has no
// IntersectionObserver for useLazyLoad to hand it to.
beforeAll(() => {
  defineRule("required", required);
  defineRule("min", min);

  vi.stubGlobal(
    "IntersectionObserver",
    class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  );
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const inventory = (image?: Record<string, string>) =>
  ({
    id: "inventory-1",
    slug: "north-locker",
    name: "North Locker",
    description: "",
    location: "",
    entriesCount: 0,
    image,
  }) as never;

const mount = async (props: Record<string, unknown> = {}) => {
  wrapper = await mountWithDefaults(Component, { props: props as never });

  return wrapper;
};

const field = (subject: VueWrapper) => subject.findComponent(FormFileInput);

const previewSrc = (subject: VueWrapper) => field(subject).props("previewSrc");

/*
 * `FormFileInput` draws an attachment from `smallUrl`, which the serializer
 * only emits for one it could build representations for. So the modal has three
 * cases to answer, not two, and each is a different picture in the frame.
 */
describe("HangarLogisticsInventoryModal preview", () => {
  it("leaves a sized attachment to the field", async () => {
    const attached = {
      smallUrl: "https://example.test/small.webp",
      mediumUrl: "https://example.test/medium.webp",
    };
    const subject = await mount({ inventory: inventory(attached) });

    expect(previewSrc(subject)).toBeUndefined();
    expect(field(subject).props("file")).toMatchObject(attached);
  });

  // The picture somebody uploaded, which fallback art must not be drawn over
  // just because no variant could be built from it.
  it("shows the original when that is all there is", async () => {
    const subject = await mount({
      inventory: inventory({ url: "https://example.test/original.webp" }),
    });

    expect(previewSrc(subject)).toBe("https://example.test/original.webp");
  });

  it("shows what the panel falls back to when nothing is attached", async () => {
    const record = inventory();
    const subject = await mount({ inventory: record });

    expect(previewSrc(subject)).toBe(
      inventoryDefaultImage(record as InventoryPanelRecord),
    );
  });

  // A create has no inventory to stand in for, so the field is an empty
  // dropzone rather than a picture of nothing in particular.
  it("offers no stand-in for an inventory that does not exist yet", async () => {
    const subject = await mount();

    expect(previewSrc(subject)).toBeUndefined();
  });
});
