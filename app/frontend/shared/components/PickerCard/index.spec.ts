import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import PanelBgImage from "@/shared/components/base/Panel/BgImage/index.vue";
import Component from "./index.vue";

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

const mount = (props: object = {}) =>
  mountWithDefaults(Component, {
    props: { name: "Gladius", subtitle: "Aegis Dynamics", ...props },
  });

describe("PickerCard", () => {
  it("shows the picture it is given", async () => {
    const wrapper = await mount({ image: "/gladius.png" });

    expect(wrapper.findComponent(PanelBgImage).props("image")).toBe(
      "/gladius.png",
    );
  });

  it("falls back to the stock picture without one", async () => {
    const wrapper = await mount();

    expect(wrapper.findComponent(PanelBgImage).props("image")).toMatch(
      /store_image/,
    );
  });

  it("prefers a placeholder to the stock picture", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { name: "Gladius" },
      slots: { placeholder: () => [h("i", { class: "icon" })] },
    });

    expect(wrapper.findComponent(PanelBgImage).exists()).toBe(false);
    expect(wrapper.find(".picker-card__placeholder .icon").exists()).toBe(true);
  });

  it("draws a contained picture as a render", async () => {
    const wrapper = await mount({ image: "/gun.png", imageFit: "contain" });

    expect(wrapper.find(".picker-card__render").attributes("src")).toBe(
      "/gun.png",
    );
    expect(wrapper.findComponent(PanelBgImage).exists()).toBe(false);
  });

  it("names the toggle after everything the card shows", async () => {
    const toggle = (
      await mount({ badges: [{ key: "hangar", label: "In hangar" }] })
    ).find(".picker-card__toggle");

    expect(toggle.attributes("aria-label")).toBe(
      "Gladius, Aegis Dynamics, In hangar",
    );
    expect(toggle.attributes("title")).toBe("Gladius · Aegis Dynamics");
  });

  it("toggles only while enabled", async () => {
    const enabled = await mount();
    await enabled.find(".picker-card__toggle").trigger("click");
    expect(enabled.emitted("toggle")).toHaveLength(1);

    const disabled = await mount({ disabled: true });
    await disabled.find(".picker-card__toggle").trigger("click");
    expect(disabled.emitted("toggle")).toBeUndefined();
  });
});
