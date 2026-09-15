import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { nextTick } from "vue";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

// jsdom reports a narrow viewport, and the chip row folds into a closed
// dropdown there -- no chip would be in the document at all.
vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => false,
}));

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  document.body.innerHTML = "";
});

const mount = async (props: Record<string, unknown> = {}) => {
  wrapper = await mountWithDefaults(Component, {
    props: { catalogue: "missions", ...props } as never,
  });

  return wrapper;
};

/*
 * The dialog teleports to the body, which is the whole point of it -- so it is
 * read off the document rather than off the wrapper's own subtree.
 */
const find = (selector: string) => document.body.querySelector(selector);

const findAll = (selector: string) =>
  Array.from(document.body.querySelectorAll(selector));

const click = async (selector: string) => {
  find(selector)?.dispatchEvent(new MouseEvent("click", { bubbles: true }));

  await nextTick();
};

const tiles = () => findAll(".preset-image");

const selected = (subject: VueWrapper) => subject.emitted("select");

describe("PresetImagePicker", () => {
  /*
   * The whole reason it carries its own overlay: the field that opens it is
   * inside a modal in the logistics forms, and the app has one modal -- going
   * through it would replace the form being filled in.
   */
  it("brings its own surface rather than the app's one modal", async () => {
    await mount();

    expect(find("[data-test='preset-picker']")).not.toBeNull();
    expect(find("[role='dialog']")?.getAttribute("aria-modal")).toBe("true");
  });

  it("opens on the record's own type", async () => {
    await mount({ group: "mining" });

    expect(tiles().length).toBeGreaterThan(0);
    expect(find("[data-test='preset-image-mining']")).not.toBeNull();
    expect(find("[data-test='preset-image-exploration']")).toBeNull();
  });

  /*
   * The whole point of the chips: the art filed under a category is a starting
   * point, not a restriction. A salvage job set at a mining site wants the
   * mining picture.
   */
  it("offers every other type one chip away", async () => {
    await mount({ group: "mining" });

    // The chip's frame carries the marker; the control inside it is the button.
    await click("[data-test='preset-group-exploration'] button");

    expect(find("[data-test='preset-image-exploration']")).not.toBeNull();
    expect(find("[data-test='preset-image-mining']")).toBeNull();
  });

  it("shows everything when no type is given", async () => {
    await mount();
    const all = tiles().length;
    wrapper?.unmount();
    document.body.innerHTML = "";

    await mount({ group: "mining" });

    expect(all).toBeGreaterThan(tiles().length);
  });

  // A kind with no art of its own would otherwise open on an empty grid.
  it("shows everything when the type it opens on carries no art", async () => {
    await mount({ catalogue: "contracts", group: "transport" });

    expect(tiles().length).toBeGreaterThan(0);
  });

  it("marks the chosen picture, and only that one", async () => {
    await mount({ group: "mining", selected: "mining_alt1" });

    const chosen = find("[data-test='preset-image-mining_alt1']");
    const other = find("[data-test='preset-image-mining']");

    expect(chosen?.classList.contains("preset-image--active")).toBe(true);
    expect(chosen?.getAttribute("aria-pressed")).toBe("true");
    expect(other?.classList.contains("preset-image--active")).toBe(false);
    expect(other?.getAttribute("aria-pressed")).toBe("false");
  });

  it("hands the choice back and closes", async () => {
    const subject = await mount({ group: "mining" });

    await click("[data-test='preset-image-mining']");

    expect(selected(subject)?.at(-1)).toEqual(["mining"]);
    expect(subject.emitted("close")).toHaveLength(1);
  });

  it("closes on the scrim and on the close action", async () => {
    const subject = await mount();

    await click("[data-test='preset-picker']");
    await click("[data-test='preset-picker-close']");

    expect(subject.emitted("close")).toHaveLength(2);
    expect(selected(subject)).toBeUndefined();
  });

  // Escape belongs to the topmost surface: a modal underneath must not read the
  // same key and close as well.
  it("closes on Escape without letting it through", async () => {
    const subject = await mount();

    const event = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });
    const reachedTheModalUnderneath = vi.fn();
    window.addEventListener("keydown", reachedTheModalUnderneath);
    window.dispatchEvent(event);
    window.removeEventListener("keydown", reachedTheModalUnderneath);

    expect(subject.emitted("close")).toHaveLength(1);
    expect(reachedTheModalUnderneath).not.toHaveBeenCalled();
  });

  it("offers a way back to no picture at all, and only once there is one", async () => {
    await mount({ group: "mining" });
    expect(find("[data-test='preset-image-remove']")).toBeNull();
    wrapper?.unmount();
    document.body.innerHTML = "";

    const subject = await mount({ group: "mining", selected: "mining" });
    await click("[data-test='preset-image-remove']");

    expect(selected(subject)?.at(-1)).toEqual([null]);
  });

  // An inventory picture is not "of" anything, so there is nothing to narrow by.
  it("renders no filter for a catalogue that is not divided", async () => {
    await mount({ catalogue: "inventories" });

    expect(find(".chip-row")).toBeNull();
    expect(tiles().length).toBeGreaterThan(0);
  });
});
