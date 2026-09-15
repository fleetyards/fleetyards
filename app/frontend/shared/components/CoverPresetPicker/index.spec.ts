import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import CoverPresetPicker from "./index.vue";

// Written as a literal rather than imported from the SFC: `tsc` only ever sees
// `*.vue` as a default export, so a type imported from there fails that pass
// even though `vue-tsc` resolves it.
const PRESETS = [
  { key: "transport", url: "/transport.webp" },
  { key: "transport_alt1", url: "/transport_alt1.webp" },
];

const mountWith = (modelValue: string | null = null, presets = PRESETS) =>
  mount(CoverPresetPicker, { props: { modelValue, presets } });

const lastEmit = (wrapper: ReturnType<typeof mountWith>) => {
  const emitted = wrapper.emitted("update:modelValue");

  return emitted?.[emitted.length - 1][0];
};

describe("CoverPresetPicker", () => {
  it("draws nothing at all when a kind has no art", () => {
    const wrapper = mountWith(null, []);

    expect(wrapper.find(".cover-presets").exists()).toBe(false);
  });

  it("draws a tile per preset, each showing its own art", () => {
    const wrapper = mountWith();
    const tiles = wrapper.findAll("button");

    expect(tiles).toHaveLength(2);
    expect(tiles[0].attributes("style")).toContain("/transport.webp");
    expect(tiles[1].attributes("style")).toContain("/transport_alt1.webp");
  });

  it("marks the chosen one, and only that one", () => {
    const wrapper = mountWith("transport_alt1");

    const chosen = wrapper.get("[data-test='cover-preset-transport_alt1']");
    const other = wrapper.get("[data-test='cover-preset-transport']");

    expect(chosen.classes()).toContain("cover-preset--active");
    expect(chosen.attributes("aria-pressed")).toBe("true");
    expect(other.classes()).not.toContain("cover-preset--active");
    expect(other.attributes("aria-pressed")).toBe("false");
  });

  it("asks for the preset that was clicked", async () => {
    const wrapper = mountWith();

    await wrapper.get("[data-test='cover-preset-transport']").trigger("click");

    expect(lastEmit(wrapper)).toBe("transport");
  });

  /*
   * The way back to "no preset". Without it a tile could only ever be swapped
   * for another one, and a form that cannot be put back the way it was found is
   * a form people stop trusting.
   */
  it("clears the preset when the chosen one is clicked again", async () => {
    const wrapper = mountWith("transport");

    await wrapper.get("[data-test='cover-preset-transport']").trigger("click");

    expect(lastEmit(wrapper)).toBeNull();
  });

  it("swaps rather than clears when a different one is clicked", async () => {
    const wrapper = mountWith("transport");

    await wrapper
      .get("[data-test='cover-preset-transport_alt1']")
      .trigger("click");

    expect(lastEmit(wrapper)).toBe("transport_alt1");
  });

  it("names the section only when it was given a label", () => {
    expect(mountWith().find(".cover-presets__label").exists()).toBe(false);

    const labelled = mount(CoverPresetPicker, {
      props: { modelValue: null, presets: PRESETS, label: "Cover presets" },
    });

    expect(labelled.get(".cover-presets__label").text()).toBe("Cover presets");
  });
});
