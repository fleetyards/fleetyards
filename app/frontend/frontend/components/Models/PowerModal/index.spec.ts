import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { computed } from "vue";
import type { PowerPreset } from "@/services/fyApi";
import type { PowerPresets } from "@/frontend/composables/usePowerPresets";
import Component from "./index.vue";

vi.mock("@/shared/composables/useMobile", async () => {
  const { ref } = await import("vue");
  return { useMobile: () => ref(false) };
});

const dogfight: PowerPreset = {
  name: "Dogfight",
  scm: [],
  nav: [{ portPath: "hardpoint_shield", pips: 2 }],
};

const presetsFor = (presets: PowerPreset[], editable: boolean) => {
  const save = vi.fn().mockResolvedValue(true);
  const context: PowerPresets = {
    presets: computed(() => presets),
    editable: computed(() => editable),
    saving: computed(() => false),
    save,
  };
  return { context, save };
};

const mount = (presets?: PowerPresets, onChange = vi.fn()) =>
  mountWithDefaults(Component, {
    props: { hardpoints: [], presets, onChange },
  });

describe("PowerPlannerModal presets", () => {
  it("has no presets on a ship's own page", async () => {
    const wrapper = await mount();

    expect(wrapper.find('[data-test="power-presets"]').exists()).toBe(false);
  });

  it("lets a visitor apply a preset but not change the list", async () => {
    const { context } = presetsFor([dogfight], false);
    const onChange = vi.fn();
    const wrapper = await mount(context, onChange);

    await wrapper
      .get('[data-test="power-preset-apply"] button')
      .trigger("click");

    expect(onChange).toHaveBeenLastCalledWith(
      { SCM: {}, NAV: { hardpoint_shield: 2 } },
      "SCM",
    );
    expect(wrapper.find('[data-test="power-preset-delete"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="power-preset-save"]').exists()).toBe(
      false,
    );
  });

  it("hides the section from a visitor when there is nothing to apply", async () => {
    const { context } = presetsFor([], false);
    const wrapper = await mount(context);

    expect(wrapper.find('[data-test="power-presets"]').exists()).toBe(false);
  });

  it("saves the current split under a new name", async () => {
    const { context, save } = presetsFor([dogfight], true);
    const wrapper = await mount(context);

    await wrapper.get('[data-test="power-preset-add"]').trigger("click");
    await wrapper.get('input[name="powerPresetName"]').setValue("Cruise");
    await wrapper.get('[data-test="power-preset-save"]').trigger("submit");

    expect(save).toHaveBeenCalledWith([
      dogfight,
      { name: "Cruise", scm: [], nav: [] },
    ]);
  });

  it("replaces a preset saved under a name that is taken", async () => {
    const { context, save } = presetsFor([dogfight], true);
    const wrapper = await mount(context);

    await wrapper.get('[data-test="power-preset-add"]').trigger("click");
    await wrapper.get('input[name="powerPresetName"]').setValue("dogfight");
    await wrapper.get('[data-test="power-preset-save"]').trigger("submit");

    expect(save).toHaveBeenCalledWith([{ name: "dogfight", scm: [], nav: [] }]);
  });

  it("deletes a preset", async () => {
    const { context, save } = presetsFor([dogfight], true);
    const wrapper = await mount(context);

    await wrapper.get('[data-test="power-presets-edit"]').trigger("click");
    await wrapper.get('[data-test="chip-edit"]').trigger("click");
    await wrapper.get('[data-test="power-preset-delete"]').trigger("click");

    expect(save).toHaveBeenCalledWith([]);
  });
});
