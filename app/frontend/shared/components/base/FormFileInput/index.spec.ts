import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { presetImageUrl } from "@/shared/composables/usePresetImages";
import PresetImagePicker from "@/shared/components/PresetImagePicker/index.vue";
import Component from "./index.vue";

// jsdom reports a narrow viewport, and the picker's chip row folds into a
// closed dropdown there.
vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => false,
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
  document.body.innerHTML = "";
});

const mount = async (
  props: Record<string, unknown> = {},
  { attached = false } = {},
) => {
  wrapper = await mountWithDefaults(Component, {
    props: { name: "coverImage", ...props } as never,
    attachTo: attached ? document.body : undefined,
  });

  return wrapper;
};

const shownImage = (subject: VueWrapper) =>
  subject.findComponent({ name: "LazyImage" });

const picker = () => wrapper?.findComponent(PresetImagePicker);

const openPicker = async (subject: VueWrapper) => {
  await subject.find("[data-test='choose-preset-coverImage']").trigger("click");
};

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

  // Its own overlay, not the app modal: this control sits inside a modal in the
  // logistics forms, and the app has one -- the picker would have replaced the
  // form being filled in.
  it("opens the picker on the record's own type, in its own surface", async () => {
    const subject = await mount({
      presetCatalogue: "missions",
      presetValue: "mining",
      presetGroup: "salvage",
    });

    expect(picker()?.exists()).toBe(false);

    await openPicker(subject);

    expect(picker()?.props()).toMatchObject({
      catalogue: "missions",
      selected: "mining",
      group: "salvage",
    });
    expect(document.body.querySelector("[data-test='preset-picker']")).not.toBe(
      null,
    );
  });

  it("hands a choice back to the form", async () => {
    const subject = await mount({ presetCatalogue: "missions" });

    await openPicker(subject);
    picker()?.vm.$emit("select", "mining");

    expect(subject.emitted("update:presetValue")?.at(-1)).toEqual(["mining"]);
  });

  it("puts the picker away once it has been answered", async () => {
    const subject = await mount({ presetCatalogue: "missions" });

    await openPicker(subject);
    picker()?.vm.$emit("close");
    await subject.vm.$nextTick();

    expect(picker()?.exists()).toBe(false);
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

    await openPicker(subject);
    picker()?.vm.$emit("select", "mining");

    expect(subject.emitted("update:modelValue")?.at(-1)).toEqual([null]);

    // The control is driven by its props, so the form answering the choice is
    // what puts the preset in front -- and the attachment is gone by then.
    await subject.setProps({ presetValue: "mining" });

    expect(shownImage(subject).props("src")).toBe(
      presetImageUrl("missions", "mining"),
    );
  });

  /*
   * The clear button used to appear only for a file, so a field showing a
   * preset had no way back to no picture except through the picker.
   */
  it("clears a preset from the field itself", async () => {
    const subject = await mount({
      presetCatalogue: "missions",
      presetValue: "mining",
      clearable: true,
    });

    await subject.find(".base-image-input__clear").trigger("click");

    expect(subject.emitted("update:presetValue")?.at(-1)).toEqual([null]);
  });

  it("offers no clear while there is nothing to clear", async () => {
    const subject = await mount({
      presetCatalogue: "missions",
      clearable: true,
    });

    expect(subject.find(".base-image-input__clear").exists()).toBe(false);
  });

  /*
   * The picker takes focus on open and contains it while it is up, so the way
   * back has to be arranged too -- otherwise closing leaves focus on `<body>`
   * and a keyboard is dropped at the top of the page.
   */
  it("returns focus to the button that opened the picker", async () => {
    // In the document, or `focus()` is a no-op and this proves nothing.
    const subject = await mount(
      { presetCatalogue: "missions" },
      { attached: true },
    );
    const button = subject.find("[data-test='choose-preset-coverImage']");

    await openPicker(subject);
    picker()?.vm.$emit("close");
    await subject.vm.$nextTick();
    await subject.vm.$nextTick();

    expect(document.activeElement).toBe(button.element);
  });

  it("leaves the picture alone when the preset is only removed", async () => {
    const subject = await mount({
      file: attachedFile,
      presetCatalogue: "missions",
      presetValue: "mining",
    });

    await openPicker(subject);
    picker()?.vm.$emit("select", null);

    expect(subject.emitted("update:presetValue")?.at(-1)).toEqual([null]);
    expect(subject.emitted("update:modelValue")).toBeUndefined();
  });
});
