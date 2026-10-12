import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { ModelPaint } from "@/services/fyApi";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useModelPaints: () => ({
    data: ref([
      { id: "paint-1", name: "Rust Society", slug: "rust", media: {} },
      { id: "paint-2", name: "Stormbringer", slug: "storm", media: {} },
    ] as ModelPaint[]),
    isLoading: ref(false),
  }),
}));

const mount = (modelValue: string | null) =>
  mountWithDefaults(Component, {
    props: { modelSlug: "ironclad", modelValue },
  });

describe("VehiclePaintPicker", () => {
  it("offers the standard livery beside every paint", async () => {
    const wrapper = await mount(null);

    expect(
      wrapper
        .findAll('[data-test="paint-picker-choice"]')
        .map((choice) => choice.text()),
    ).toEqual(["Standard livery", "Rust Society", "Stormbringer"]);
  });

  it("marks the paint the ship wears", async () => {
    const wrapper = await mount("paint-2");

    const pressed = wrapper
      .findAll('[data-test="paint-picker-choice"]')
      .filter((choice) => choice.attributes("aria-pressed") === "true")
      .map((choice) => choice.text());

    expect(pressed).toEqual(["Stormbringer"]);
  });

  it("picks a paint, and clears it again with the standard livery", async () => {
    const wrapper = await mount("paint-1");
    const choices = wrapper.findAll('[data-test="paint-picker-choice"]');

    await choices[2].trigger("click");
    await choices[0].trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([["paint-2"], [null]]);
  });
});
