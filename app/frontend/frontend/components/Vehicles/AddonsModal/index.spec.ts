import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { ModelModule, Vehicle } from "@/services/fyApi";
import Component from "./index.vue";

const modules = ref<{ items: ModelModule[] }>({
  items: [
    { id: "m1", name: "Cargo Module", slug: "cargo" },
    { id: "m2", name: "Combat Module", slug: "combat" },
  ] as unknown as ModelModule[],
});

const resolved = () => ({
  isPending: ref(false),
  isFetching: ref(false),
  isLoading: ref(false),
  isRefetching: ref(false),
  error: ref(undefined),
});

// Partial: the row and the contents summary reach for real enums from here.
vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelModulePackages: () => ({ data: ref(undefined), ...resolved() }),
  useModelModules: () => ({ data: modules, ...resolved() }),
  useModelUpgrades: () => ({ data: ref([]), ...resolved() }),
}));

const mutateAsync = vi.fn(() => Promise.resolve());

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync, isPending: ref(false) }),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const vehicle = (modelModuleIds: string[] = []): Vehicle =>
  ({
    id: "v1",
    modelModuleIds,
    modelUpgradeIds: [],
    model: { name: "Retaliator", slug: "retaliator" },
  }) as unknown as Vehicle;

const mountModal = async (v: Vehicle) => {
  const wrapper = mount(Component, {
    props: { vehicle: v, editable: true },
    global: {
      plugins: [createTestingPinia()],
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
      },
      directives: { Tooltip: {} },
    },
  });
  await flushPromises();
  return wrapper;
};

const rowToggle = (
  wrapper: Awaited<ReturnType<typeof mountModal>>,
  i: number,
) => wrapper.findAll("[data-test='vehicle-addon-toggle']")[i];

describe("AddonsModal", () => {
  /**
   * The whole broken chain in one assertion: a row click has to reach the form
   * field and land in the payload. It used to stop at the row.
   */
  it("saves the selection a row click made", async () => {
    const wrapper = await mountModal(vehicle());

    await rowToggle(wrapper, 0).trigger("click");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      id: "v1",
      data: { modelModuleIds: ["m1"], modelUpgradeIds: [] },
    });
  });

  // Reassigning the initial values never reached the form, so the modal kept
  // answering for whichever ship it was first opened for.
  it("re-seeds the fields when the ship it was opened for changes", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    expect(wrapper.findAll(".addon-option--selected")).toHaveLength(1);

    await wrapper.setProps({ vehicle: vehicle(["m2"]) });
    await flushPromises();

    const selected = wrapper.findAll(".addon-option--selected");
    expect(selected).toHaveLength(1);
    expect(selected[0].text()).toContain("Combat Module");
  });

  // A background refetch of the hangar must not discard an unsaved choice.
  it("keeps a pending choice when the ship refreshes underneath it", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    await rowToggle(wrapper, 1).trigger("click");
    await wrapper.setProps({ vehicle: vehicle(["m1"]) });
    await flushPromises();

    expect(wrapper.findAll(".addon-option--selected")).toHaveLength(2);
  });
});
