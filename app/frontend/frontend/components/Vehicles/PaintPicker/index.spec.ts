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

const mount = (modelValue: string[], pledgedIds: string[] = []) =>
  mountWithDefaults(Component, {
    props: { modelSlug: "ironclad", modelValue, pledgedIds },
  });

const choices = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll('[data-test="paint-picker-choice"]');

describe("VehiclePaintPicker", () => {
  it("offers every paint of the model", async () => {
    const wrapper = await mount([]);

    expect(choices(wrapper).map((choice) => choice.text())).toEqual([
      "Rust Society",
      "Stormbringer",
    ]);
  });

  it("marks the paints the ship owns", async () => {
    const wrapper = await mount(["paint-1", "paint-2"]);

    expect(
      choices(wrapper).map((choice) => choice.attributes("aria-pressed")),
    ).toEqual(["true", "true"]);
  });

  it("adds a paint and removes one", async () => {
    const wrapper = await mount(["paint-1"]);

    await choices(wrapper)[1].trigger("click");
    await choices(wrapper)[0].trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([
      [["paint-1", "paint-2"]],
      [[]],
    ]);
  });

  it("marks a paint a pledge suggests", async () => {
    const wrapper = await mount([], ["paint-2"]);

    expect(
      choices(wrapper).map((choice) =>
        choice.find('[data-test="paint-picker-pledged"]').exists(),
      ),
    ).toEqual([false, true]);
  });
});
