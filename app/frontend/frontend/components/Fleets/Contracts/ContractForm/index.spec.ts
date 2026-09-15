import { describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";

const createMutation = vi.fn(() => Promise.resolve({ slug: "job-1" }));
const updateMutation = vi.fn(() => Promise.resolve({ slug: "job-1" }));

// Mocked as a module, not stubbed at mount: the real one reaches HoloViewer and
// pulls three.js in, which does not resolve under vitest.
const { clear } = vi.hoisted(() => ({ clear: vi.fn() }));

vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: {
    name: "FormFileInput",
    props: ["modelValue", "file", "previewSrc"],
    template: "<div />",
    setup: () => ({ clear }),
  },
}));

vi.mock("@/services/fyApi", () => ({
  FleetContractKindEnum: {
    TRANSPORT: "transport",
    PROCUREMENT: "procurement",
    CRAFTING: "crafting",
  },
  useFleetInventories: () => ({ data: { value: { items: [] } } }),
  useCreateFleetContract: () => ({ mutateAsync: createMutation }),
  useUpdateFleetContract: () => ({ mutateAsync: updateMutation }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn() }),
}));

vi.mock("vue-router", () => ({ useRouter: () => ({ push: vi.fn() }) }));

// Two pictures for one kind, so choosing and swapping are both reachable.
vi.mock("@/frontend/composables/useContractCover", () => ({
  useContractCover: () => ({
    presetsFor: (kind: string) =>
      kind === "transport"
        ? [
            { key: "transport", url: "/transport.webp" },
            { key: "transport_alt1", url: "/transport_alt1.webp" },
          ]
        : [],
  }),
}));

import ContractForm from "./index.vue";

const FLEET = { slug: "black-sun", name: "Black Sun" };

const mountForm = (contract?: Record<string, unknown>) =>
  mount(ContractForm, {
    props: { fleet: FLEET as never, contract: contract as never },
    global: {
      stubs: {
        FormTabs: { template: "<div><slot /></div>" },
        FormTab: { template: "<div><slot /></div>" },
        FormActions: true,
        FormInput: true,
        FormTextarea: true,
        FormToggle: true,
        FormDateTime: true,
        BaseSelect: true,
      },
    },
  });

const vm = (wrapper: ReturnType<typeof mountForm>) =>
  wrapper.vm as unknown as {
    coverImage: string | null | undefined;
    coverImagePreset: string | null;
    kind: string;
  };

const SAVED_COVER = {
  slug: "job-1",
  kind: "transport",
  coverImage: { url: "/saved.png", smallUrl: "/saved-small.png" },
  coverImagePreset: null,
};

describe("ContractForm cover", () => {
  /*
   * The one that matters: `useContractCover` prefers an attachment over any
   * preset, so a saved cover left in place would make choosing a preset look
   * like it did nothing. `null` is how the API is told to detach it.
   */
  it("detaches a saved cover when a preset is chosen", async () => {
    const wrapper = mountForm(SAVED_COVER);

    await wrapper
      .getComponent({ name: "CoverPresetPicker" })
      .vm.$emit("update:modelValue", "transport_alt1");

    expect(vm(wrapper).coverImagePreset).toBe("transport_alt1");
    expect(vm(wrapper).coverImage).toBeNull();
  });

  // Nothing attached, nothing to detach: `undefined` drops the key instead of
  // asking the API to remove a cover that was never there.
  it("asks to detach nothing when there is no saved cover", async () => {
    const wrapper = mountForm({ slug: "job-1", kind: "transport" });

    await wrapper
      .getComponent({ name: "CoverPresetPicker" })
      .vm.$emit("update:modelValue", "transport");

    expect(vm(wrapper).coverImage).toBeUndefined();
  });

  /*
   * Picking a tile asks for the saved cover to be detached; unpicking it has to
   * withdraw that request. Otherwise a author who tried a preset and changed
   * their mind would still lose the picture they started with.
   */
  it("puts the saved cover back when the chosen tile is unpicked", async () => {
    const wrapper = mountForm(SAVED_COVER);

    const picker = wrapper.getComponent({ name: "CoverPresetPicker" });
    await picker.vm.$emit("update:modelValue", "transport");

    expect(vm(wrapper).coverImage).toBeNull();

    await picker.vm.$emit("update:modelValue", null);

    expect(vm(wrapper).coverImagePreset).toBeNull();
    expect(vm(wrapper).coverImage).toBeUndefined();
  });

  /*
   * The sequence that makes the value alone insufficient: the author clears the
   * file themselves, then tries a preset, then changes their mind. Their clear
   * has to survive all of it -- withdrawing the preset's detach must not also
   * withdraw theirs.
   */
  it("keeps a clear the author made when a preset is picked and unpicked", async () => {
    const wrapper = mountForm(SAVED_COVER);

    // What FormFileInput emits when its clear button is used.
    await wrapper
      .getComponent({ name: "FormFileInput" })
      .vm.$emit("update:modelValue", null);

    const picker = wrapper.getComponent({ name: "CoverPresetPicker" });
    await picker.vm.$emit("update:modelValue", "transport");
    await picker.vm.$emit("update:modelValue", null);

    expect(vm(wrapper).coverImage).toBeNull();
  });

  /*
   * The order that hides the problem: picking first sets the same `null` the
   * author's clear would, so a clear afterwards changes nothing visible. The
   * form still has to notice it was theirs, or unpicking puts the cover back.
   */
  it("keeps a clear the author made after picking a preset", async () => {
    const wrapper = mountForm(SAVED_COVER);

    const picker = wrapper.getComponent({ name: "CoverPresetPicker" });
    await picker.vm.$emit("update:modelValue", "transport");

    // What FormFileInput emits when its clear button is used.
    await wrapper
      .getComponent({ name: "FormFileInput" })
      .vm.$emit("update:modelValue", null);

    await picker.vm.$emit("update:modelValue", null);

    expect(vm(wrapper).coverImage).toBeNull();
  });

  // An upload made after the preset was picked must not be thrown away by
  // unpicking it either.
  it("keeps an upload made after the preset was picked", async () => {
    const wrapper = mountForm(SAVED_COVER);

    const picker = wrapper.getComponent({ name: "CoverPresetPicker" });
    await picker.vm.$emit("update:modelValue", "transport");

    await wrapper
      .getComponent({ name: "FormFileInput" })
      .vm.$emit("update:modelValue", "signed-id-1");

    await picker.vm.$emit("update:modelValue", null);

    expect(vm(wrapper).coverImage).toBe("signed-id-1");
  });

  // The picker only ever offers the current kind's art, so a selection made
  // before the kind changed is no longer on it.
  it("drops a preset the new kind does not offer", async () => {
    const wrapper = mountForm(SAVED_COVER);

    await wrapper
      .getComponent({ name: "CoverPresetPicker" })
      .vm.$emit("update:modelValue", "transport_alt1");

    vm(wrapper).kind = "crafting";
    await wrapper.vm.$nextTick();

    expect(vm(wrapper).coverImagePreset).toBeNull();
  });
});
