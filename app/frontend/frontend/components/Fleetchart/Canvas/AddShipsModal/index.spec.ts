import { describe, expect, it, vi } from "vitest";
import { shallowMount } from "@vue/test-utils";
import AddShipsModal from "./index.vue";
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

describe("FleetchartCanvasAddShipsModal", () => {
  it("offers drawable ships, several of each", () => {
    const picker = shallowMount(AddShipsModal, {
      props: { add: vi.fn() },
    }).findComponent(PickerModal);

    expect(picker.props("query")).toEqual({ hasFleetchartViews: true });
    expect(picker.props("quantities")).toBe(true);
  });

  it("hands over the selection and closes without asking", () => {
    const add = vi.fn();
    const selection = [{ option: { id: "hornet" }, quantity: 2 }];

    shallowMount(AddShipsModal, { props: { add } })
      .findComponent(PickerModal)
      .vm.$emit("submit", selection);

    expect(add).toHaveBeenCalledWith(selection);
    expect(emit).toHaveBeenCalledWith("close-modal", true);
  });
});
