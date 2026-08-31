import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { BTN_CONTAINER } from "./context";
import { BtnSizesEnum, BtnTonesEnum, BtnVariantsEnum } from "./types";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayConfirm: vi.fn() }),
}));

const RouterLinkStub = {
  props: ["to", "activeClass", "exactActiveClass"],
  template: "<a><slot /></a>",
};

const mountBtn = (
  props: Record<string, unknown> = {},
  provide: Record<symbol, unknown> = {},
) =>
  mount(Component, {
    props,
    slots: { default: "Label" },
    global: {
      provide,
      stubs: { "router-link": RouterLinkStub },
    },
  });

describe("BaseBtn", () => {
  it("defaults to the sm size", () => {
    expect(mountBtn().classes()).toContain("btn--sm");
  });

  it("keeps variant and tone on separate axes", () => {
    // The old single `variant` enum could not express a quiet destructive button.
    const wrapper = mountBtn({
      variant: BtnVariantsEnum.GHOST,
      tone: BtnTonesEnum.DANGER,
    });

    expect(wrapper.classes()).toContain("btn--ghost");
    expect(wrapper.classes()).toContain("btn--tone-danger");
  });

  it("renders an anchor for href", () => {
    const wrapper = mountBtn({ href: "https://fleetyards.net" });

    expect(wrapper.element.tagName).toBe("A");
    expect(wrapper.attributes("rel")).toBe("noopener");
  });

  it("renders a disabled button rather than an anchor when disabled", () => {
    // `disabled` has no effect on <a>, so the old component left disabled link
    // buttons clickable and focusable.
    const wrapper = mountBtn({
      href: "https://fleetyards.net",
      disabled: true,
    });

    expect(wrapper.element.tagName).toBe("BUTTON");
    expect(wrapper.attributes("disabled")).toBeDefined();
    expect(wrapper.attributes("href")).toBeUndefined();
  });

  it("does not navigate a router link while loading", () => {
    const wrapper = mountBtn({ to: { name: "home" }, loading: true });

    expect(wrapper.element.tagName).toBe("BUTTON");
    expect(wrapper.attributes("disabled")).toBeDefined();
  });

  it("keeps the label while loading and marks the button busy", () => {
    // The old component replaced the label with "Loading", changing the
    // accessible name mid-interaction.
    const wrapper = mountBtn({ loading: true });

    expect(wrapper.text()).toContain("Label");
    expect(wrapper.attributes("aria-busy")).toBe("true");
    expect(wrapper.get(".btn__status").text()).toBe("baseBtn.labels.loading");
  });

  it("announces loading, which nothing visual is required for", () => {
    // The caps carry it visually, and they are decoration as far as assistive
    // technology is concerned - this is the only thing that announces it.
    const wrapper = mountBtn({ loading: true });

    expect(wrapper.find(".btn__status").exists()).toBe(true);
  });

  it("emits click when there is nothing to confirm", async () => {
    const wrapper = mountBtn();
    await wrapper.trigger("click");

    expect(wrapper.emitted("click")).toHaveLength(1);
  });

  it("withholds the click until a confirm is resolved", async () => {
    const wrapper = mountBtn({ confirm: "Sure?" });
    await wrapper.trigger("click");

    expect(wrapper.emitted("click")).toBeUndefined();
  });

  it("adapts to a group container without the group styling it", () => {
    // BtnGroup states that it contains buttons; Btn decides what that means, so
    // the group never needs descendant selectors into these internals.
    const wrapper = mountBtn(
      {},
      {
        [BTN_CONTAINER as unknown as symbol]: {
          container: "group",
          size: { value: BtnSizesEnum.LG },
          block: { value: true },
        },
      },
    );

    expect(wrapper.classes()).toContain("btn--grouped");
    expect(wrapper.classes()).toContain("btn--grouped-block");
    // The container's size wins over the default, but not over an explicit prop.
    expect(wrapper.classes()).toContain("btn--lg");
  });

  it("lets an explicit size override the container", () => {
    const wrapper = mountBtn(
      { size: BtnSizesEnum.MD },
      {
        [BTN_CONTAINER as unknown as symbol]: {
          container: "group",
          size: { value: BtnSizesEnum.LG },
          block: { value: false },
        },
      },
    );

    expect(wrapper.classes()).toContain("btn--md");
  });

  it("adapts to a dropdown menu container", () => {
    const wrapper = mountBtn(
      {},
      {
        [BTN_CONTAINER as unknown as symbol]: {
          container: "menu",
          size: { value: undefined },
          block: { value: false },
        },
      },
    );

    expect(wrapper.classes()).toContain("btn--menu-item");
    expect(wrapper.classes()).not.toContain("btn--grouped");
  });

  it("passes attributes such as data-test and aria-label through", () => {
    // 91 call sites hook on data-test and 55 on aria-label.
    const wrapper = mountBtn({
      "data-test": "the-button",
      "aria-label": "Sync hangar",
    });

    expect(wrapper.attributes("data-test")).toBe("the-button");
    expect(wrapper.attributes("aria-label")).toBe("Sync hangar");
  });
});
