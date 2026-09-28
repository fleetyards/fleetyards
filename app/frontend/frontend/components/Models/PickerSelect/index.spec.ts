import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { useComlink } from "@/shared/composables/useComlink";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  useModel: () => ({
    data: ref({
      name: "Hull C",
      media: { storeImage: { smallUrl: "hull.jpg" } },
    }),
  }),
}));

const mount = (modelValue?: string) =>
  mountWithDefaults(Component, {
    props: { name: "ship", label: "Your ship", modelValue },
  });

describe("ModelPickerSelect", () => {
  it("keeps its label and prompts for a ship while empty", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".field-label").text()).toBe("Your ship");
    expect(
      wrapper.find('[data-test="model-picker-select-trigger"]').text(),
    ).toBe("Select a Ship");
    expect(
      wrapper.find('[data-test="model-picker-select-clear"]').exists(),
    ).toBe(false);
  });

  it("names the chosen ship and offers to clear it", async () => {
    const wrapper = await mount("misc-hull-c");

    expect(
      wrapper.find('[data-test="model-picker-select-trigger"]').text(),
    ).toBe("Hull C");

    expect(wrapper.find(".field-label").text()).toBe("Your ship");

    await wrapper
      .find('[data-test="model-picker-select-clear"]')
      .trigger("click");

    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([undefined]);
  });

  it("opens the ship picker", async () => {
    const opened = vi.fn();
    const off = useComlink().on("open-modal", opened);
    const wrapper = await mount();

    await wrapper
      .find('[data-test="model-picker-select-trigger"]')
      .trigger("click");

    expect(opened).toHaveBeenCalledOnce();
    off();
  });

  it("takes only the pick made for this select", async () => {
    const wrapper = await mount();
    const comlink = useComlink();

    comlink.emit("model-picker-select-picked", {
      pickerId: "another",
      slug: "c2",
    });
    expect(wrapper.emitted("update:modelValue")).toBeUndefined();

    const opened = vi.fn();
    const off = comlink.on("open-modal", opened);
    await wrapper
      .find('[data-test="model-picker-select-trigger"]')
      .trigger("click");
    const { pickerId } = opened.mock.calls[0][0].props;
    off();

    comlink.emit("model-picker-select-picked", {
      pickerId,
      slug: "misc-hull-c",
    });
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual(["misc-hull-c"]);
  });
});
