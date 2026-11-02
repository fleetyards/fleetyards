import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { VehiclePublic } from "@/services/fyApi";
import Component from "./index.vue";

const resolved = () => ({
  isPending: ref(false),
  isFetching: ref(false),
  isLoading: ref(false),
  isRefetching: ref(false),
  error: ref(undefined),
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelModules: () => ({
    data: ref({
      items: [
        { id: "m1", slug: "cargo", name: "Cargo Module" },
        { id: "m2", slug: "living", name: "Living Module" },
      ],
    }),
    ...resolved(),
  }),
  useModelUpgrades: () => ({
    data: ref([{ id: "u1", name: "Hull Kit" }]),
    ...resolved(),
  }),
}));

const vehicle = (overrides: Partial<VehiclePublic> = {}) =>
  ({
    id: "v1",
    name: "Big Bertha",
    modelModuleIds: ["m1", "m1"],
    modelUpgradeIds: [],
    model: {
      name: "Retaliator",
      slug: "retaliator",
      hasModules: true,
      hasUpgrades: true,
    },
    ...overrides,
  }) as unknown as VehiclePublic;

const mount = (props: { vehicle: VehiclePublic }) =>
  mountWithDefaults(Component, { props });

describe("VehicleAddonsView", () => {
  it("lists the modules the ship carries, without the rest of the catalogue", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    const rows = wrapper.findAll("[data-test='vehicle-addon']");

    expect(rows).toHaveLength(1);
    expect(rows[0].text()).toContain("Cargo Module");
    expect(wrapper.text()).not.toContain("Living Module");
  });

  it("says when the ship carries no upgrade kits", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    expect(wrapper.text()).not.toContain("Hull Kit");
    expect(wrapper.text()).toContain("No upgrade kits fitted");
  });

  it("leaves out a section the model has no add-ons for", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        model: {
          name: "Retaliator",
          slug: "retaliator",
          hasModules: true,
          hasUpgrades: false,
        } as VehiclePublic["model"],
      }),
    });

    expect(wrapper.text()).not.toContain("No upgrade kits fitted");
  });
});
