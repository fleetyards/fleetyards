import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const emit = vi.hoisted(() => vi.fn());

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: vi.fn() }),
}));

describe("BlueprintLogImportBtn", () => {
  it("opens the import modal", async () => {
    const wrapper = await mountWithDefaults(Component);

    await wrapper
      .find("[data-test='open-blueprint-log-import']")
      .trigger("click");

    expect(emit).toHaveBeenCalledWith("open-modal", expect.anything());
  });
});
