import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { presetImageUrl } from "@/shared/composables/usePresetImages";
import Component from "./index.vue";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: () => () => undefined }),
}));

// The holo branch pulls in three.js, which will not resolve under vitest -- and
// none of this is about holos.
vi.mock("@/shared/components/HoloViewer/index.vue", () => ({
  default: { name: "HoloViewer", template: "<div />" },
}));

// The control draws its picture through LazyImage, and jsdom has no
// IntersectionObserver for useLazyLoad to hand it to.
beforeAll(() => {
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
  emit.mockClear();
});

const mount = async (props: Record<string, unknown> = {}) => {
  wrapper = await mountWithDefaults(Component, {
    props: { name: "coverImage", ...props } as never,
  });

  return wrapper;
};

const shownImage = (subject: VueWrapper) =>
  subject.findComponent({ name: "LazyImage" });

const openModal = () =>
  emit.mock.calls.find(([event]) => event === "open-modal")?.[1];

const attachedSmallUrl = "https://example.test/cover.webp";

const attachedFile = {
  name: "cover.webp",
  contentType: "image/webp",
  smallUrl: attachedSmallUrl,
} as never;

describe("FormFileInput presets", () => {
  it("draws a chosen preset the way it draws an upload", async () => {
    const subject = await mount({
      presetCatalogue: "missions",
      presetValue: "mining",
    });

    expect(shownImage(subject).props("src")).toBe(
      presetImageUrl("missions", "mining"),
    );
  });

  /*
   * Everything that renders one of these records prefers the attachment, so a
   * preset drawn over one would show a picture that appears nowhere else.
   */
  it("keeps the attached picture in front of a preset", async () => {
    const subject = await mount({
      file: attachedFile,
      presetCatalogue: "missions",
      presetValue: "mining",
    });

    expect(shownImage(subject).props("src")).toBe(attachedSmallUrl);
  });

  // A stand-in the caller supplies is what the record falls back to; a preset
  // is what somebody picked.
  it("draws a preset over a stand-in preview", async () => {
    const subject = await mount({
      previewSrc: "https://example.test/default.webp",
      presetCatalogue: "missions",
      presetValue: "mining",
    });

    expect(shownImage(subject).props("src")).toBe(
      presetImageUrl("missions", "mining"),
    );
  });

  it("offers the catalogue only where there is one", async () => {
    const without = await mount();
    expect(
      without.find("[data-test='choose-preset-coverImage']").exists(),
    ).toBe(false);
    wrapper?.unmount();

    const subject = await mount({ presetCatalogue: "missions" });
    expect(
      subject.find("[data-test='choose-preset-coverImage']").exists(),
    ).toBe(true);
  });

  it("opens the picker on the record's own type", async () => {
    const subject = await mount({
      presetCatalogue: "missions",
      presetValue: "mining",
      presetGroup: "salvage",
    });

    await subject
      .find("[data-test='choose-preset-coverImage']")
      .trigger("click");

    expect(openModal()?.props).toMatchObject({
      catalogue: "missions",
      selected: "mining",
      group: "salvage",
    });
  });

  it("hands a choice back to the form", async () => {
    const subject = await mount({ presetCatalogue: "missions" });

    await subject
      .find("[data-test='choose-preset-coverImage']")
      .trigger("click");
    openModal()?.props.onSelect("mining");

    expect(subject.emitted("update:presetValue")?.at(-1)).toEqual(["mining"]);
  });

  /*
   * The two are exclusive, and the field is where that is decided: a preset
   * chosen while a picture is attached would otherwise save both and go on
   * showing the attachment.
   */
  it("clears the attached picture when a preset is chosen", async () => {
    const subject = await mount({
      file: attachedFile,
      presetCatalogue: "missions",
    });

    await subject
      .find("[data-test='choose-preset-coverImage']")
      .trigger("click");
    openModal()?.props.onSelect("mining");

    expect(subject.emitted("update:modelValue")?.at(-1)).toEqual([null]);

    // The control is driven by its props, so the form answering the choice is
    // what puts the preset in front -- and the attachment is gone by then.
    await subject.setProps({ presetValue: "mining" });

    expect(shownImage(subject).props("src")).toBe(
      presetImageUrl("missions", "mining"),
    );
  });

  it("leaves the picture alone when the preset is only removed", async () => {
    const subject = await mount({
      file: attachedFile,
      presetCatalogue: "missions",
      presetValue: "mining",
    });

    await subject
      .find("[data-test='choose-preset-coverImage']")
      .trigger("click");
    openModal()?.props.onSelect(null);

    expect(subject.emitted("update:presetValue")?.at(-1)).toEqual([null]);
    expect(subject.emitted("update:modelValue")).toBeUndefined();
  });
});
