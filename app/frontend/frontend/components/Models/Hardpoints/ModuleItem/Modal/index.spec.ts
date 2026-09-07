import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { ModelModule } from "@/services/fyApi";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const modul = (slug: string, name: string): ModelModule =>
  ({ id: slug, name, slug, media: {} }) as unknown as ModelModule;

const MODULES = [modul("cargo", "Front Cargo"), modul("torp", "Front Torpedo")];

const mountModal = async (selectedModuleSlug?: string) => {
  const onSelect = vi.fn();
  const wrapper = mount(Component, {
    props: { modules: MODULES, selectedModuleSlug, onSelect },
    global: {
      plugins: [createTestingPinia()],
      stubs: { Modal: { template: "<div><slot /></div>" } },
      directives: { Tooltip: {} },
    },
  });
  await flushPromises();
  return { wrapper, onSelect };
};

describe("ModuleItemModal", () => {
  /**
   * The slot row hands this modal its props through an untyped dynamic import,
   * so nothing type-checks the boundary — only a mount catches a prop the caller
   * does not pass.
   */
  it("clears the slot through onSelect, the only callback it is given", async () => {
    const { wrapper, onSelect } = await mountModal("cargo");

    await wrapper
      .find("[data-test='module-option-stock-toggle']")
      .trigger("click");

    expect(onSelect).toHaveBeenCalledWith(null);
    expect(emit).toHaveBeenCalledWith("close-modal");
  });

  it("picks the module whose row was pressed", async () => {
    const { wrapper, onSelect } = await mountModal();

    await wrapper
      .findAll("[data-test='module-option-toggle']")[1]
      .trigger("click");

    expect(onSelect).toHaveBeenCalledWith(MODULES[1]);
  });

  it("marks the stock row when the slot holds nothing", async () => {
    const { wrapper } = await mountModal();

    expect(
      wrapper.find("[data-test='module-option-stock']").classes(),
    ).toContain("addon-option--selected");
  });

  it("marks the row for the module the slot holds", async () => {
    const { wrapper } = await mountModal("torp");

    const rows = wrapper.findAll("[data-test='module-option']");

    expect(rows[0].classes()).not.toContain("addon-option--selected");
    expect(rows[1].classes()).toContain("addon-option--selected");
  });
});
