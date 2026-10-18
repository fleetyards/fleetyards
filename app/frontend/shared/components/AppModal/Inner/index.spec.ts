import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { h } from "vue";
import { flushPromises } from "@vue/test-utils";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import Component from "./index.vue";

describe("AppModalInner", () => {
  it("sizes the footer's buttons medium and leaves the body's alone", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      slots: {
        default: () => [h(Btn, { "data-test": "body-btn" }, () => "Body")],
        footer: () => [h(Btn, { "data-test": "footer-btn" }, () => "Footer")],
      },
    });

    expect(wrapper.get("[data-test='footer-btn']").classes()).toContain(
      "btn--md",
    );
    expect(wrapper.get("[data-test='body-btn']").classes()).toContain(
      "btn--sm",
    );
  });

  it("lays the body out as a column only when asked to fill it", async () => {
    const plain = await mountWithDefaults<typeof Component>(Component);
    const filled = await mountWithDefaults<typeof Component>(Component, {
      props: { fillBody: true },
    });

    expect(plain.get(".modal-body").classes()).not.toContain(
      "modal-body--fill",
    );
    expect(filled.get(".modal-body").classes()).toContain("modal-body--fill");
  });

  describe("as a sheet on a phone", () => {
    // jsdom has no matchMedia.
    const sheetWidth = (matches: boolean) =>
      vi.stubGlobal(
        "matchMedia",
        vi.fn(() => ({ matches })),
      );

    let stopListening: (() => void) | undefined;

    afterEach(() => {
      stopListening?.();
      vi.unstubAllGlobals();
    });

    const drag = async (distance: number, pointerType = "touch") => {
      const closed = vi.fn();
      stopListening = useComlink().on("close-modal", closed);

      const wrapper = await mountWithDefaults<typeof Component>(Component, {
        props: { title: "Edit" },
      });
      const header = wrapper.get(".modal-header").element;

      // jsdom has no PointerEvent, and a MouseEvent's clientY cannot be set.
      const pointer = (type: string, clientY = 0) => {
        const event = new Event(type, { bubbles: true });
        Object.assign(event, { pointerType, clientY, pointerId: 1 });
        header.dispatchEvent(event);
      };

      pointer("pointerdown", 100);
      pointer("pointermove", 100 + distance);
      pointer("pointerup");
      await flushPromises();

      return { closed, wrapper };
    };

    it("closes when dragged down far enough", async () => {
      sheetWidth(true);

      const { closed } = await drag(140);

      expect(closed).toHaveBeenCalledTimes(1);
    });

    it("springs back from a short drag", async () => {
      sheetWidth(true);

      const { closed, wrapper } = await drag(40);

      expect(closed).not.toHaveBeenCalled();
      expect(
        (wrapper.get(".modal-inner").element as HTMLElement).style.transform,
      ).toBe("");
    });

    it("leaves a mouse alone", async () => {
      sheetWidth(true);

      const { closed } = await drag(140, "mouse");

      expect(closed).not.toHaveBeenCalled();
    });

    it("does not drag where the modal is not a sheet", async () => {
      sheetWidth(false);

      const { closed } = await drag(140);

      expect(closed).not.toHaveBeenCalled();
    });
  });
});
