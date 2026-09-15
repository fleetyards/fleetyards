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

  /*
   * Escape belongs to the topmost surface. The app modal and the confirm dialog
   * both listen on `window` in the bubble phase and are mounted long before
   * this is, so the probe is registered the same way and in the same order --
   * dispatching straight at `window` instead proves nothing, because then the
   * two listeners are on the target together and order alone decides.
   */
  it("closes on Escape without the surface underneath reading it too", async () => {
    const underneath = vi.fn();
    window.addEventListener("keydown", underneath);

    const subject = await mount();

    // From inside the dialog, which is where focus is while it is open.
    find("[data-test='preset-picker-close']")?.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );

    window.removeEventListener("keydown", underneath);

    expect(subject.emitted("close")).toHaveLength(1);
    expect(underneath).not.toHaveBeenCalled();
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

  /*
   * `aria-modal` says everything behind this is inert, and the keyboard has to
   * agree with that claim. The form underneath is still tabbable and still
   * looks focusable, so without this Tab walks straight out of the dialog and
   * into a form the reader cannot see.
   */
  describe("focus", () => {
    const dialog = () =>
      document.body.querySelector<HTMLElement>("[role='dialog']");

    const focusable = () =>
      Array.from(
        dialog()?.querySelectorAll<HTMLElement>(
          "a[href], button:not([disabled]), [tabindex]:not([tabindex='-1'])",
        ) ?? [],
      );

    const tab = (shiftKey = false) =>
      window.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Tab",
          shiftKey,
          bubbles: true,
          cancelable: true,
        }),
      );

    it("takes focus when it opens, on the thing that carries its name", async () => {
      await mount();

      expect(document.activeElement).toBe(dialog());
    });

    it("wraps forwards off the last control", async () => {
      await mount();
      const items = focusable();

      items[items.length - 1].focus();
      tab();

      expect(document.activeElement).toBe(items[0]);
    });

    it("wraps backwards off the first", async () => {
      await mount();
      const items = focusable();

      items[0].focus();
      tab(true);

      expect(document.activeElement).toBe(items[items.length - 1]);
    });

    // Whatever Tab was about to reach, it was not inside the dialog.
    it("pulls focus back when it has escaped", async () => {
      await mount();
      const outside = document.createElement("button");
      document.body.append(outside);
      outside.focus();

      tab();

      expect(document.activeElement).toBe(focusable()[0]);
      outside.remove();
    });
  });

  // An inventory picture is not "of" anything, so there is nothing to narrow by.
  it("renders no filter for a catalogue that is not divided", async () => {
    await mount({ catalogue: "inventories" });

    expect(find(".chip-row")).toBeNull();
    expect(tiles().length).toBeGreaterThan(0);
  });
});
