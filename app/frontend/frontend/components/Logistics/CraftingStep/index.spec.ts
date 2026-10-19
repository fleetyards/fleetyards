import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

const slot = vi.hoisted(() => (position: number, graded = true) => ({
  position,
  name: `Slot ${position}`,
  options: [{ type: "resource", commodityKey: "taranite" }],
  modifiers: graded
    ? [
        {
          name: "Impact Force",
          propertyKey: "gpp_weapon_damage",
          ramp: "linear",
          startQuality: 0,
          endQuality: 1000,
          modifierAtStart: 0.95,
          modifierAtEnd: 1.05,
        },
      ]
    : [],
}));

// The hooks, not the fetchers: a generated hook calls its own fetcher from
// inside the module, which a mocked export never reaches.
vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref } = await import("vue");

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    useBlueprints: vi.fn(() => ({
      data: ref({
        items: [{ id: "bp-1", name: "Bulwark", slug: "bulwark" }],
        meta: {},
      }),
    })),
    useBlueprint: vi.fn(() => ({
      data: ref({
        id: "bp-1",
        name: "Bulwark",
        slug: "bulwark",
        costSlots: [slot(1), slot(2), slot(3, false)],
      }),
    })),
  };
});

vi.mock("@/frontend/components/Blueprints/Preview/index.vue", () => ({
  default: { name: "BlueprintPreview", render: () => null },
}));

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (qualities: Record<string, number | undefined> = {}) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      item: { type: "Component", id: "bulwark-item", name: "Bulwark" },
      modelValue: { blueprintId: "bp-1", qualities },
      "onUpdate:modelValue": (value: unknown) =>
        wrapper?.setProps({ modelValue: value } as never),
    },
  });
  await flushPromises();

  return wrapper;
};

describe("LogisticsCraftingStep", () => {
  // A slot that moves no stat takes any grade, and nobody is asked for one.
  it("asks for a grade in each slot that moves a stat", async () => {
    const subject = await mount();

    expect(subject.find("[data-test='input-craftedQuality1']").exists()).toBe(
      true,
    );
    expect(subject.find("[data-test='input-craftedQuality2']").exists()).toBe(
      true,
    );
    expect(subject.find("[data-test='input-craftedQuality3']").exists()).toBe(
      false,
    );
  });

  it("is valid once every graded slot has a grade", async () => {
    const subject = await mount();

    expect(subject.emitted("valid")?.at(-1)).toEqual([false]);

    await subject.find("[data-test='input-craftedQuality1']").setValue("750");
    await subject.find("[data-test='input-craftedQuality2']").setValue("500");
    await flushPromises();

    expect(subject.emitted("valid")?.at(-1)).toEqual([true]);
    expect((subject.props() as { modelValue: unknown }).modelValue).toEqual({
      blueprintId: "bp-1",
      qualities: { 1: 750, 2: 500 },
    });
  });

  it("does not take a grade above 1000", async () => {
    const subject = await mount({ 1: 750 });

    await subject.find("[data-test='input-craftedQuality2']").setValue("1200");
    await flushPromises();

    expect(subject.emitted("valid")?.at(-1)).toEqual([false]);
  });
});
